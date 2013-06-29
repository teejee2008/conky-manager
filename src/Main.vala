/*
 * Main.vala
 * 
 * Copyright 2013 Tony George <teejee@teejee-pc>
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 * MA 02110-1301, USA.
 * 
 * 
 */
 
using GLib;
using Gtk;
using Gee;

public Main App;
public const string AppName = "Conky Manager";
public const string AppVersion = "1.1";
public const string AppAuthor = "Tony George";
public const string AppAuthorEmail = "teejee2008@gmail.com";
public const bool LogTimestamp = false;
public const bool UseConsoleColors = true;
public const bool EnableDebuggingMessages = true;

const string GETTEXT_PACKAGE = "conky-manager";
const string LOCALE_DIR = "/usr/share/locale";

public class Main : GLib.Object {
	
	public string ThemeDir = "";
	public Gee.ArrayList<ConkyTheme> ThemeList;

    public static int main(string[] args) {
		
		// set locale
		
		Intl.setlocale(GLib.LocaleCategory.MESSAGES, "");
		Intl.textdomain(GETTEXT_PACKAGE);
		Intl.bind_textdomain_codeset(GETTEXT_PACKAGE, "utf-8");
		Intl.bindtextdomain(GETTEXT_PACKAGE, LOCALE_DIR);
		
		// initialize
		
		Gtk.init (ref args);
		App = new Main(args[0]);

		var window = new MainWindow ();
		window.destroy.connect (App.exit_app);
		window.show_all ();

	    Gtk.main ();
	    
        return 0;
    }
    
    public Main(string arg0) {
		string home = Environment.get_home_dir ();

		ThemeDir = home + "/conky-manager/themes";
		
		//create missing directories --------
		
		string path = "";

		path = home + "/conky-manager";
		if (Utility.dir_exists(path) == false){
			Utility.create_dir(path);
			debug(_("Directory Created") + ": " + path);
		}
		
		path = home + "/conky-manager/themes";
		if (Utility.dir_exists(path) == false){
			Utility.create_dir(path);
			debug(_("Directory Created") + ": " + path);
		}
		
		path = home + "/.fonts";
		if (Utility.dir_exists(path) == false){
			Utility.create_dir(path);
			debug(_("Directory Created") + ": " + path);
		}
		
		path = home + "/.config/autostart";
		if (Utility.dir_exists(path) == false){
			Utility.create_dir(path);
			debug(_("Directory Created") + ": " + path);
		}
		
		if (get_installed_theme_count() == 0){
			// install shared theme pack ---------------
			string sharePath = "/usr/share/conky-manager";
			string pkgPath = sharePath + "/conky-manager-theme-pack.zip";
			if (Utility.file_exists(pkgPath)){
				install_theme_pack(pkgPath);
			}

			//install theme packs -----------
			string appPath = (File.new_for_path (arg0)).get_parent().get_path ();
			pkgPath = appPath + "/conky-manager-theme-pack.zip";
			if (Utility.file_exists(pkgPath)){
				install_theme_pack(pkgPath);
			} 
		}
		
		//load themes --------
		
		reload_themes();
		start_status_thread();
	}
	
	public int get_installed_theme_count(){
		string home = Environment.get_home_dir ();
		string path = home + "/conky-manager/themes";
		var directory = File.new_for_path (path);
		int count = 0;
		
		try{
			var enumerator = directory.enumerate_children (FileAttribute.STANDARD_NAME, 0);
			FileInfo info;
			while ((info = enumerator.next_file ()) != null) {
				if (info.get_file_type () == FileType.DIRECTORY){
					count++;
				}
			}
		}
        catch(Error e){
	        log_error (e.message);
	    }
		
        return count;
	}
	
	public int check_for_new_themes(){
		string sharePath = "/usr/share/conky-manager";
		string pkgPath = sharePath + "/conky-manager-theme-pack.zip";
		if (Utility.file_exists(pkgPath)){
			return install_theme_pack(pkgPath, true);
		}
			
		return 0;
	}
	
	public int install_new_themes(){
		string sharePath = "/usr/share/conky-manager";
		string pkgPath = sharePath + "/conky-manager-theme-pack.zip";
		if (Utility.file_exists(pkgPath)){
			return install_theme_pack(pkgPath, false);
		}
			
		return 0;
	}
	
	public int install_theme_pack(string pkgPath, bool checkOnly = false){
		string temp_dir = Environment.get_tmp_dir();
		temp_dir = temp_dir + "/" + Utility.timestamp2();
		Utility.create_dir(temp_dir);
		
		debug(_("Found ThemePack") + ": " + pkgPath);
		
		string cmd = "cd \"" + temp_dir + "\"\n";
		cmd += "unzip  \"" + pkgPath + "\"\n";
		Utility.execute_command_sync_batch (cmd); 
		
		int count = 0;
		
		try
		{
			File f_temp_dir = File.parse_name (temp_dir);
	        FileEnumerator enumerator = f_temp_dir.enumerate_children (FileAttribute.STANDARD_NAME, 0);
	
	        FileInfo file;
	        while ((file = enumerator.next_file ()) != null) {
				string source_dir = temp_dir + "/" + file.get_name();
				string target_dir = ThemeDir + "/" + file.get_name();
				
				if (Utility.dir_exists(target_dir)) { 
					continue; 
				}
				else{
					count++;
					
					if (!checkOnly){
						//install
						debug(_("Theme Copied") + ": " + target_dir);
						Posix.system("cp -r \"" + source_dir + "\" \"" + target_dir + "\"");
					}
				}
	        } 
        }
        catch(Error e){
	        log_error (e.message);
	    }

		Posix.system("rm -rf \"" + temp_dir + "\"");
		
		return count;
	}
	
	public void reload_themes() {
		ThemeList = new Gee.ArrayList<ConkyTheme>();

		try
		{
			File fileThemeDir = File.parse_name (ThemeDir);
	        FileEnumerator enumerator = fileThemeDir.enumerate_children (FileAttribute.STANDARD_NAME, 0);
	
	        FileInfo file;
	        while ((file = enumerator.next_file ()) != null) {
				string item = ThemeDir + "/" + file.get_name();
				if (Utility.dir_exists(item) == false) { continue; }

		        ConkyTheme theme = new ConkyTheme(item);
		        ThemeList.add(theme);
	        } 
        }
        catch(Error e){
	        log_error (e.message);
	    }
	}
	
	public void refresh_status() {
		Gee.ArrayList<string> ActiveConfigList = new Gee.ArrayList<string>();

		string cmd = "conky -c "; //without double-quotes
		string txt = Utility.execute_command_sync_get_output ("ps w -C conky"); 
		//use 'ps ew -C conky' for all users
	
		foreach(string line in txt.split("\n")){
			if (line.index_of(cmd) != -1){
				string conf = line.substring(line.index_of(cmd) + 8).strip();
				ActiveConfigList.add(conf);
			}
		}
		
		foreach(ConkyTheme theme in ThemeList){
			foreach(ConkyConfig conf in theme.ConfigList){
				bool active = false;
				foreach(string path in ActiveConfigList){
					if (conf.Path == path){
						active = true;
					}
				}
				conf.Enabled = active;
			}
		}
	}	
	
	public void start_status_thread ()
	{
		try {
			Thread.create<void> (status_thread, true);
		} catch (ThreadError e) {
			log_error (e.message);
		}
	}
	
	private void status_thread ()
	{
		while (true){  // loop runs for entire application lifetime
			refresh_status();
			Thread.usleep((ulong)3000000);
		}
	}
	
	private void exit_app(){
		update_startup_script();
		
		if (check_startup()){
			autostart(true); //overwrite the startup entry
		}
	}
	
	public void update_startup_script(){
		string home = Environment.get_home_dir ();
		string startupScript = home + "/conky-manager/conky-startup.sh";
		
		string txt= "killall conky\n";
		foreach(ConkyTheme theme in ThemeList){
			foreach(ConkyConfig conf in theme.ConfigList){
				if (conf.Enabled){
					txt += "cd \"" + theme.BasePath + "\"\n";
					txt += "conky -c \"" + conf.Path + "\" &\n";
				}
			}
		}

		Utility.write_file(startupScript, txt);
	}
	
	public bool check_startup(){
		string home = Environment.get_home_dir ();
		string startupFile = home + "/.config/autostart/conky.desktop";
		return Utility.file_exists(startupFile);	
	}
	
	public void autostart(bool autostart){
		string home = Environment.get_home_dir ();
		string startupFile = home + "/.config/autostart/conky.desktop";
		
		if (autostart){
			string txt = 
"""[Desktop Entry]
Type=Application
Exec={command}
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name[en_IN]=Conky
Name=Conky
Comment[en_IN]=
Comment=
""";
			txt = txt.replace("{command}", "sh \"" + home + "/conky-manager/conky-startup.sh\"");
			
			Utility.write_file(startupFile, txt);
		}
		else{
			Utility.file_delete(startupFile);			
		}
	}
	
	public void kill_all_conky(){
		Posix.system("killall conky");
	}
}

public class ConkyTheme : GLib.Object {
	
	public string Name = "";
	public string Author = "";
	public string WebLink = "";
	public string PreviewSmall = "";
	public string PreviewLarge = "";
	//public bool Enabled = false;
	public string BasePath = "";
	public string PreviewImage = "";
	public string InfoFile = "";

	public Gee.ArrayList<ConkyConfig> ConfigList;
	public Gee.ArrayList<string> FontList;
	
	public ConkyTheme(string path) {
		File f = File.new_for_path (path);
		
		BasePath = path;
		Name = f.get_basename();
		ConfigList = new Gee.ArrayList<ConkyConfig>();
		FontList = new Gee.ArrayList<string>();

		PreviewImage = path + "/preview.png";

		//find conkyrc files 
		find_conkyrc(BasePath, true);
		find_conkyrc(BasePath + "/config", false);

		//find font files
		find_fonts(BasePath);
		find_fonts(BasePath + "/fonts");
		
		//find info file
		string infoFile = BasePath + "/info.txt";
		if (Utility.file_exists(infoFile)){
			InfoFile = infoFile;
		}
		
		//find preview image
		string previewFile = BasePath + "/preview.png";
		if (Utility.file_exists(previewFile)){
			PreviewImage = previewFile;
		}
	}
	
	private void find_conkyrc(string dirPath, bool checkExt)
	{
		try
		{
			FileEnumerator enumerator;
			FileInfo file;
			File fileDir = File.parse_name (dirPath);
				
			if (Utility.dir_exists(dirPath)){
				enumerator = fileDir.enumerate_children (FileAttribute.STANDARD_NAME, 0);
		
				while ((file = enumerator.next_file ()) != null) {
					string filePath = dirPath + "/" + file.get_name();
					if (Utility.file_exists(filePath) == false) { continue; }
					if (filePath.has_suffix("~")) { continue; } //ignore backups of config files
					if (checkExt && (filePath.down().has_suffix(".conkyrc") == false)) { continue; }
					
					var conf = new ConkyConfig(filePath, this);
					ConfigList.add(conf);
					
					debug(_("Found Config") + ": " + filePath);
				} 
			}
		}
        catch(Error e){
	        log_error (e.message);
	    }
	}
	
	private void find_fonts(string dirPath)
	{
		try
		{
			FileEnumerator enumerator;
			FileInfo file;
			File directory = File.parse_name (dirPath);
				
	        if (Utility.dir_exists(dirPath)){
				enumerator = directory.enumerate_children (FileAttribute.STANDARD_NAME, 0);
		
				while ((file = enumerator.next_file ()) != null) {
					string item = dirPath + "/" + file.get_name();
					if (Utility.file_exists(item) == false) { continue; }
					
					string name = file.get_name();
					string ext = name[name.last_index_of(".",0):name.length].down();
					if ((ext != ".ttf") && (ext != ".odt")) { continue; }
					
					FontList.add(item);
				} 
			}
		}
        catch(Error e){
	        log_error (e.message);
	    }
	}
	
	//install fonts and install required packages
	public void Install(){
		string home = Environment.get_home_dir ();
		
		// check and install fonts
		foreach (string filePath in FontList) {
			File fontFile = File.new_for_path (filePath);
			string fileName = fontFile.get_basename();
			string targetFile = home + "/.fonts/" + fileName;
			
			if (Utility.file_exists(targetFile) == false){
				Utility.copy_file(filePath, targetFile);
				debug(_("Font Installed: ") + targetFile);
			}
		}
	}
	
	public bool Enabled{
		get{
			bool allEnabled = true;
			foreach(ConkyConfig conf in ConfigList){
				if (conf.Enabled == false){
					allEnabled = false;
					break;
				}
			}
			
			if (ConfigList.size == 0){
				allEnabled = false;
			}
			
			return allEnabled;
		}
		
		set{
			foreach(ConkyConfig conf in ConfigList){
				if (conf.Enabled != value){
					if(value == true){
						conf.start_conky();
					}
					else{
						conf.stop_conky();
					}
				}
			}
		}
	}
}


public class ConkyConfig : GLib.Object {
	public ConkyTheme Theme;
	public string Name;
	public string Path;
	public bool Enabled = false;
	
	public ConkyConfig(string configPath, ConkyTheme theme) {
		Theme = theme;
		Path = configPath;
		
		File f = File.new_for_path (configPath);
		Name = f.get_basename();
	}
	
	public void start_conky(){
		if (Enabled) {
			return;
		}
		
		Theme.Install();
		
		string cmd = "cd \"" + Theme.BasePath + "\"\n";
		cmd += "conky -c \"" + Path + "\"\n";
		Utility.execute_command_async_batch (cmd); 
		Thread.usleep((ulong)1000000);
		debug(_("Started") + ": " + Path);
		
		//set the flag for immediate effect
		//will be updated by the refresh_status() timer
		Enabled = true; 
	}
	
	public void stop_conky(){
		if (!Enabled) {
			return;
		}
		
		//Note: There may be more than one running instance of the same config
		//We need to kill all instances
		
		string cmd = "conky -c " + Path; //without double-quotes
		string txt = Utility.execute_command_sync_get_output ("ps w -C conky");
		//use 'ps ew -C conky' for all users
		
		string pid = "";
		foreach(string line in txt.split("\n")){
			if (line.index_of(cmd) != -1){
				pid = line.strip().split(" ")[0];
				Posix.kill ((Pid) int.parse(pid), 15);
				debug(_("Stopped") + ": [PID=" + pid + "] " + Path);
			}
		}
		
		//set the flag for immediate effect
		//will be updated by the refresh_status() timer
		Enabled = false; 
	}
	
	public void restart_conky(){
		if (Enabled) {
			stop_conky();
		}
		start_conky();
	}
	
	public string alignment{
		owned get{
			string s = get_value("alignment");
			if (s == "") { s = "top_left"; }
			debug("Get: alignment " + s);
			return s;
		}
		set
		{
			string newLine = "alignment " + value;
			set_value("alignment", newLine);
			debug("Set: alignment " + value);
		}
	}
	
	public string gap_x{
		owned get{
			string s = get_value("gap_x");
			if (s == "") { s = "0"; }
			debug("Get: gap_x " + s);
			return s;
		}
		set
		{
			string newLine = "gap_x " + value;
			set_value("gap_x", newLine);
			debug("Set: gap_x " + value);
		}
	}
	
	public string gap_y{
		owned get{
			string s = get_value("gap_y");
			if (s == "") { s = "0"; }
			debug("Get: gap_y " + s);
			return s;
		}
		set
		{
			string newLine = "gap_y " + value;
			set_value("gap_y", newLine);
			debug("Set: gap_y " + value);
		}
	}
	
	public string own_window_transparent{
		owned get{
			string s = get_value("own_window_transparent");
			if (s == "") { s = ""; }
			debug("Get: own_window_transparent " + s);
			return s;
		}
		set
		{
			string newLine = "own_window_transparent " + value;
			set_value("own_window_transparent", newLine);
			debug("Set: own_window_transparent " + value);
		}
	}
	
	public string own_window_argb_visual{
		owned get{
			string s = get_value("own_window_argb_visual");
			if (s == "") { s = ""; }
			debug("Get: own_window_argb_visual " + s);
			return s;
		}
		set
		{
			string newLine = "own_window_argb_visual " + value;
			set_value("own_window_argb_visual", newLine);
			debug("Set: own_window_argb_visual " + value);
		}
	}
	
	public string own_window_argb_value{
		owned get{
			string s = get_value("own_window_argb_value");
			if (s == "") { s = ""; }
			debug("Get: own_window_argb_value " + s);
			return s;
		}
		set
		{
			string newLine = "own_window_argb_value " + value;
			set_value("own_window_argb_value", newLine);
			debug("Set: own_window_argb_value " + value);
		}
	}
	
	public string own_window_colour{
		owned get{
			string s = get_value("own_window_colour");
			if (s == "") { s = "000000"; }
			debug("Get: own_window_colour " + s);
			return s.up();
		}
		set
		{
			string newLine = "own_window_colour " + value.up();
			set_value("own_window_colour", newLine);
			debug("Set: own_window_colour " + value.up());
		}
	}
	
	public string minimum_size{
		owned get{
			string s = get_value("minimum_size");
			if ((s == "")||(s.split(" ").length != 2)) { s = "0 0"; }
			debug("Get: minimum_size " + s);
			return s;
		}
		set
		{
			string newLine = "minimum_size " + value;
			set_value("minimum_size", newLine);
			debug("Set: minimum_size " + value);
		}
	}
	
	public int height_padding{
		get{
			
			string text = Utility.read_file(this.Path);
			string[] arr = text.split("\n");
			int count = 0;
			
			//count empty lines at end of the file
			for(int k = arr.length - 1; k >= 0; k--){
				if (arr[k].strip() == ""){
					count++;
				}
				else{
					break;
				}
			}
			
			count--;
			
			debug("Set: height_padding " + count.to_string());
			
			return count;
		}
		set
		{
			string text = Utility.read_file(this.Path);
			string newText = "";
			string[] arr = text.split("\n");
			int count = 0;
			
			//count empty lines at end of the file
			for(int k = arr.length - 1; k >= 0; k--){
				if (arr[k].strip() == ""){
					count++;
				}
				else{
					break;
				}
			}
			
			int lastLineNumber = arr.length - count;
			
			//remove all empty lines from end of text
			for(int k = 0; k < lastLineNumber; k++){
				newText += arr[k] + "\n";
			}
			//remove extra newline from end of text
			//newText = newText[0:newText.length-1];
			
			//add empty lines at end of text
			for(int k = 1; k <= value; k++){
				newText += "\n";
			}
			
			debug("Set: height_padding " + value.to_string());
			Utility.write_file(this.Path, newText);
		}
	}
	
	public string get_value(string param){
		foreach(string line in Utility.read_file(Path).split("\n")){
			string s = line.down().strip();
			if (s.has_prefix(param)){
				if (s.index_of(" ") != -1){
					return s[s.index_of(" ")+1:s.length].strip();
				}
				else if (s.index_of("\t") != -1){
					return s[s.index_of("\t")+1:s.length].replace("\t"," ").strip();
				}
			}
		}
		
		return "";
	}
	
	public void set_value(string param, string newLine){
		string oldText = Utility.read_file(this.Path);
		string newText = "";
		bool found = false;
		bool remove = (newLine.strip() == param);
		
		foreach(string line in oldText.split("\n")){
			string s = line.down().strip();
			if (s.has_prefix(param)){
				if (!remove){
					//replace line
					newText += newLine + "\n";
				}
				found = true;
			}
			else if ((s == "text")&&(!found)){
				if (!remove){
					//insert line
					newText += newLine + "\n";
				}
				newText += line + "\n";
				found = true;
			}
			else{
				newText += line + "\n";
			}
		}
		
		//remove extra newline from end of text
		newText = newText[0:newText.length-1];
		
		Utility.write_file(this.Path, newText);
	}
}
