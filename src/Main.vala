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
public const string AppVersion = "1.2";
public const string AppAuthor = "Tony George";
public const string AppAuthorEmail = "teejee2008@gmail.com";
public const bool LogTimestamp = false;
public const bool UseConsoleColors = true;
public const bool EnableDebuggingMessages = true;

const string GETTEXT_PACKAGE = "conky-manager";
const string LOCALE_DIR = "/usr/share/locale";

public class Main : GLib.Object {
	
	public string UserPath = "";
	public Gee.ArrayList<ConkyTheme> ThemeList;
	public bool EditMode = false;
	
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
		UserPath = home + "/conky-manager";
		
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
		
		//install new theme packs and fonts ---------------
		
		check_shared_theme_packs();

		//load themes --------
		
		reload_themes();
		start_status_thread();
	}
	
	public void check_shared_theme_packs(){
		string sharePath = "/usr/share/conky-manager/themepacks";
		string home = Environment.get_home_dir ();
		string config_file = home + "/conky-manager/.themepacks";
		
		//delete config file if no themes found
		if (get_installed_theme_count() == 0) { 
			Posix.system("rm -f \"" + config_file + "\""); 
		}
		
		//create empty config file if missing
		if (Utility.file_exists(config_file) == false) { 
			Posix.system("touch \"" + config_file + "\""); 
		}

		//read config file
		string txt = Utility.read_file(config_file);
		string[] filenames = txt.split("\n");
			
		try
		{
			FileEnumerator enumerator;
			FileInfo file;
			File fShare = File.parse_name (sharePath);
				
			if (Utility.dir_exists(sharePath)){
				enumerator = fShare.enumerate_children (FileAttribute.STANDARD_NAME, 0);
		
				while ((file = enumerator.next_file ()) != null) {
					
					string filePath = sharePath + "/" + file.get_name();
					if (Utility.file_exists(filePath) == false) { continue; }
					if (filePath.has_suffix(".cmtp.7z") == false) { continue; }
					
					bool is_installed = false;
					foreach(string filename in filenames){
						if (file.get_name() == filename){
							debug(_("Found theme pack [installed]") + ": " + filePath);
							is_installed = true;
							break;
						}
					}
					
					if (!is_installed){
						debug("-----------------------------------------------------");
						debug(_("Found theme pack [new]") + ": " + filePath);
						install_theme_pack(filePath);
						debug("-----------------------------------------------------");
						
						string list = "";
						foreach(string filename in filenames){
							list += filename + "\n";
						}
						list += file.get_name() + "\n";
						Utility.write_file(config_file,list);
					}
				} 
			}
		}
        catch(Error e){
	        log_error (e.message);
	    }
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
	
	public int install_theme_pack(string pkgPath, bool checkOnly = false){
		string cmd = "";
		string home = Environment.get_home_dir ();
		string temp_dir = Environment.get_tmp_dir();
		temp_dir = temp_dir + "/" + Utility.timestamp2();
		Utility.create_dir(temp_dir);
		
		debug(_("Installing") + ": " + pkgPath);
		
		cmd = "cd \"" + temp_dir + "\"\n";
		cmd += "7z x \"" + pkgPath + "\">nul\n";
		Utility.execute_command_sync_batch (cmd); 
		
		string temp_dir_themes = temp_dir + "/themes";
		string temp_dir_fonts = temp_dir + "/fonts";
		string temp_dir_home = temp_dir + "/home";
		int count = 0;
	
		//copy themes to ~/conky-manager/themes

		try
		{	
			if (Utility.dir_exists(temp_dir_themes)){

				File f_themes_dir = File.parse_name (temp_dir_themes);
				FileEnumerator enumerator = f_themes_dir.enumerate_children (FileAttribute.STANDARD_NAME, 0);
				FileInfo file;
				
				while ((file = enumerator.next_file ()) != null) {
					string source_dir = temp_dir_themes + "/" + file.get_name();
					string target_dir = UserPath + "/themes/" + file.get_name();

					if (Utility.dir_exists(target_dir)) { 
						continue; 
					}
					else{
						count++;
						
						if (!checkOnly){
							//install
							debug(_("Theme copied") + ": " + target_dir);
							Posix.system("cp -r \"" + source_dir + "\" \"" + target_dir + "\"");
						}
					}
				} 
			}
        }
        catch(Error e){
	        log_error (e.message);
	    }
	    
	    //copy fonts to ~/.fonts
	    
		try{
			if (Utility.dir_exists(temp_dir_fonts)){
				File f_fonts_dir = File.parse_name (temp_dir_fonts);
				FileEnumerator enumerator = f_fonts_dir.enumerate_children (FileAttribute.STANDARD_NAME, 0);
				
				FileInfo file;
				while ((file = enumerator.next_file ()) != null) {
					string source_file = temp_dir_fonts + "/" + file.get_name();
					string target_file = home + "/.fonts/" + file.get_name();
					
					if (Utility.file_exists(target_file)) { 
						continue; 
					}
					else{
						if (!checkOnly){
							//install
							debug(_("Font copied") + ": " + target_file);
							Posix.system("cp -r \"" + source_file + "\" \"" + target_file + "\"");
						}
					}
				} 
			}
        }
        catch(Error e){
	        log_error (e.message);
	    }

		//copy files to ~
		
		try{
			 
			if (Utility.dir_exists(temp_dir_home)){
				
				File f_home_dir = File.parse_name (temp_dir_home);
				FileEnumerator enumerator = f_home_dir.enumerate_children (FileAttribute.STANDARD_NAME, 0);
				FileInfo file;
				
				while ((file = enumerator.next_file ()) != null) {
					string dir_name = file.get_name();
					string dir_path = temp_dir_home + "/" + file.get_name();
					
					if ((dir_name.down() == "conky")||(dir_name.down() == ".conky")||(dir_name == ".fonts")){
						if (Utility.dir_exists(dir_path)) { 
							debug(_("Copy files: ") + home + "/" + dir_name);
							cmd = "rsync --recursive --perms --chmod=a=rwx \"" + dir_path + "\" \"" + home + "\"";
							Posix.system(cmd);
						}
					} 
				} 
			}
        }
        catch(Error e){
	        log_error (e.message);
	    }
	    
		//delete temp files
		Posix.system("rm -rf \"" + temp_dir + "\"");
		
		return count;
	}
	
	public void reload_themes() {
		ThemeList = new Gee.ArrayList<ConkyTheme>();
		
		string theme_dir = UserPath + "/themes";
		
		try
		{
			debug("-----------------------------------------------------");
			debug(_("Loading themes") + ": " + theme_dir );
		
			File fileThemeDir = File.parse_name (theme_dir);
	        FileEnumerator enumerator = fileThemeDir.enumerate_children (FileAttribute.STANDARD_NAME, 0);
	
	        FileInfo file;
	        while ((file = enumerator.next_file ()) != null) {
				string item = theme_dir + "/" + file.get_name();
				if (Utility.dir_exists(item) == false) { continue; }

		        ConkyTheme theme = new ConkyTheme(item);
		        ThemeList.add(theme);
	        } 

			//sort the theme list
			CompareFunc<ConkyTheme> theme_compare = (a, b) => {
				return strcmp(a.Name,b.Name);
			};
			ThemeList.sort(theme_compare);
	        
	        debug("-----------------------------------------------------");
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
		if (EditMode){
			run_startup_script();
		}
		else{
			update_startup_script();
		}
		
		if (check_startup()){
			autostart(true); //overwrite the startup entry
		}
	}
	
	public void run_startup_script(){
		string home = Environment.get_home_dir ();
		Utility.execute_command_sync("sh \"" + home + "/conky-manager/conky-startup.sh\"");
		Posix.usleep(500000);//microseconds
		refresh_status();
	}
	
	public void update_startup_script(){
		if (EditMode){ 
			debug("WARNING: update_startup_script() invoked in edit mode");
			return;
		}
		
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
		refresh_status();
	}
	
	public void minimize_all_other_windows(){
		string txt =
"""#!/usr/bin/env python
import wnck
import gtk

screen = wnck.screen_get_default()

while gtk.events_pending():
    gtk.main_iteration()

windows = screen.get_windows()
active = screen.get_active_window()

for w in windows:
    if w != active and w.get_name().find("Conky") == -1:
        w.minimize()
""";
        
        string temp_dir = Environment.get_tmp_dir();
		temp_dir = temp_dir + "/" + Utility.timestamp2();
		Utility.create_dir(temp_dir);
		string py_file = temp_dir + "/minimize.py";
		
        Utility.write_file(py_file, txt);
	    Utility.chmod (py_file, "u+x");

        Posix.system(py_file);
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
					
					string theme_dir = Environment.get_home_dir() + "/conky-manager/themes";
		
					debug(_("Found config") + ": " + filePath.replace(theme_dir + "/",""));
				} 
				
				//sort the widget list
				CompareFunc<ConkyConfig> rc_compare = (a, b) => {
					return strcmp(a.Name,b.Name);
				};
				ConfigList.sort(rc_compare);
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
	public string Text = "";

	public ConkyConfig(string configPath, ConkyTheme theme) {
		Theme = theme;
		Path = configPath;
		
		File f = File.new_for_path (configPath);
		Name = f.get_basename();
	}
	
	private void update_status(){
		//status for all config is updated periodically by a timer
		//this function updates the status immediately
		
		string cmd = "conky -c " + Path; //without double-quotes
		string txt = Utility.execute_command_sync_get_output ("ps w -C conky"); 
		//use 'ps ew -C conky' for all users
		
		bool active = false;
		foreach(string line in txt.split("\n")){
			if (line.index_of(cmd) != -1){
				active = true;
				break;
			}
		}
		Enabled = active;
	}
	
	public void start_conky(){
		update_status();
		if (Enabled){
			stop_conky();
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
	
	public void read_file(){
		debug("Read config file from disk");
		Text = Utility.read_file(Path);
	}
	
	public void write_changes_to_file(){
		debug("Saved config file changes to disk");
		Utility.write_file(this.Path, Text);
	}
	
	public string alignment{
		owned get{
			string s = get_value("alignment");
			
			switch(s){
				case "tl":
					s = "top_left";
					break;
				case "tr":
					s = "top_right";
					break;
				case "tm":
					s = "top_middle";
					break;
				case "bl":
					s = "bottom_left";
					break;
				case "br":
					s = "bottom_right";
					break;
				case "bm":
					s = "bottom_middle";
					break;
				case "ml":
					s = "middle_left";
					break;
				case "mr":
					s = "middle_right";
					break;
				case "mm":
					s = "middle_middle";
					break;
				case "":
					s = "top_left";
					break;
			}

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
			string[] arr = this.Text.split("\n");
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
			
			debug("Get: height_padding " + count.to_string());
			
			return count;
		}
		set
		{
			string newText = "";
			string[] arr = this.Text.split("\n");
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
			
			this.Text = newText;
		}
	}
	
	public string time_format{
		owned get{
			string val = "";
			
			if (search("""\${(time|TIME) [^}]*H[^}]*}""") != ""){
				val = "24";
				debug("Get: time format = 24-hour");
			}
			else if (search("""\${(time|TIME) [^}]*I[^}]*}""") != ""){
				val = "12";
				debug("Get: time format = 12-hour");
			}

			return val;
		}
		set
		{
			if (value == "") { return; }
			
			switch(value){
				case "12":
					if (replace("""\${(time|TIME) [^}]*(H)[^}]*}""", 2, "I")){
						debug("Set: time format = 12-hour");
					}
					break;
				case "24":
					if (replace("""\${(time|TIME) [^}]*(I)[^}]*}""", 2, "H")){
						debug("Set: time format = 24-hour");
					}
					break;	
			}
		}
	}
	
	public string network_device{
		owned get{
			string var1 = "totaldown|totalup|upspeed|upspeedf|downspeed|downspeedf|wireless_ap|wireless_bitrate|wireless_essid|wireless_link_qual|wireless_link_qual_max|wireless_link_qual_perc|wireless_mode";
			var1 = """\${(""" + var1 + "|" + var1.up() + """)[ \t]*([A-Za-z0-9]+)[ \t]*}""";
			
			string var2 = "upspeedgraph|downspeedgraph";
			var2 = """\${(""" + var2 + "|" + var2.up() + """)[ \t]*([A-Za-z0-9]+)[ \t]*.*}""";
			
			string var3 = "wireless_link_bar";
			var3 = """\${(""" + var3 + "|" + var3.up() + """)[ \t]*[0-9]+[ \t]*,[0-9+][ \t]*([A-Za-z0-9]+)[ \t]*}""";

			string net = search(var1, 2);
			
			if (net != ""){
				debug("Get: network interface = " + net);
				return net;
			}
			
			net = search(var2, 2);
			
			if (net != ""){
				debug("Get: network interface = " + net);
				return net;
			}
			
			net = search(var3, 2);
			
			if (net != ""){
				debug("Get: network interface = " + net);
				return net;
			}
			
			return "";
		}
		set
		{
			if (value == "") { return; }
			
			string var1 = "totaldown|totalup|upspeed|upspeedf|downspeed|downspeedf|wireless_ap|wireless_bitrate|wireless_essid|wireless_link_qual|wireless_link_qual_max|wireless_link_qual_perc|wireless_mode";
			var1 = """\${(""" + var1 + "|" + var1.up() + """)[ \t]*([A-Za-z0-9]+)[ \t]*}""";
			
			string var2 = "upspeedgraph|downspeedgraph";
			var2 = """\${(""" + var2 + "|" + var2.up() + """)[ \t]*([A-Za-z0-9]+)[ \t]*.*}""";
			
			string var3 = "wireless_link_bar";
			var3 = """\${(""" + var3 + "|" + var3.up() + """)[ \t]*[0-9]+[ \t]*,[0-9+][ \t]*([A-Za-z0-9]+)[ \t]*}""";

			string net = search(var1, 2);
			
			if (net != ""){
				if (replace(var1, 2, value)){
					debug("Set: network interface = " + value);
				}
			}
			
			net = search(var2, 2);
			
			if (net != ""){
				if (replace(var2, 2, value)){
					debug("Set: network interface = " + value);
				}
			}
			
			net = search(var3, 2);
			
			if (net != ""){
				if (replace(var3, 2, value)){
					debug("Set: network interface = " + value);
				}
			}
		}
	}
	
	public string get_value(string param){
		foreach(string line in this.Text.split("\n")){
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
		string newText = "";
		bool found = false;
		bool remove = (newLine.strip() == param);
		
		foreach(string line in this.Text.split("\n")){
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
		
		this.Text = newText;
	}
	
	public string search(string search_string, int bracket_num = 0){
		foreach(string line in this.Text.split("\n")){
			string s = line.strip();

			try{
				Regex regx = new Regex(search_string);
				MatchInfo match;
				if (regx.match(s, 0, out match)){
					return match.fetch(bracket_num);
				}
			} catch (Error e) {
				log_error (e.message);
			}
		}
		
		return "";
	}
	
	public bool replace(string search_string, int bracket_num, string replace_string){
		bool found = false;
		string new_text = "";
		string old_match = "";
		string new_match = "";
		string new_line = "";
		
		foreach(string line in this.Text.split("\n")){
			try{
				Regex regx = new Regex(search_string);
				MatchInfo match;
				if (regx.match(line, 0, out match)){
					
					bool matchExists = true;
					new_line = line;
					
					while (matchExists){
						old_match = match.fetch(0);
						new_match = old_match.replace(match.fetch(bracket_num),replace_string);
						//debug("old_match=%s\nnew_match=%s\n".printf(old_match,new_match));
						new_line = new_line.replace(old_match, new_match);
						matchExists = match.next();
					}
					
					new_text += new_line + "\n";
					found = true;
				}
				else{
					new_text += line + "\n";
				}
			} catch (Error e) {
				log_error (e.message);
				return false;
			}
		}
		
		//remove extra newline from end of text
		new_text = new_text[0:new_text.length-1];
		
		this.Text = new_text;
		
		return found;
	}
}
