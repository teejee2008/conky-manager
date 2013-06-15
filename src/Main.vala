/*
 * Main.vala
 * 
 * Copyright 2012 Tony George <teejee@teejee-pc>
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
public const string AppVersion = "1.0";
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
		ThemeDir = (File.new_for_path (arg0)).get_parent ().get_path ();
		ThemeDir = ThemeDir + "/themes";
		
		//create missing directories --------
		
		string path = "";
		string home = Environment.get_home_dir ();
		
		path = home + "/conky";
		if (Utility.dir_exists(path) == false){
			Utility.create_dir(path);
			debug("Directory Created: " + path);
		}
		
		path = home + "/.fonts";
		if (Utility.dir_exists(path) == false){
			Utility.create_dir(path);
			debug("Directory Created: " + path);
		}
		
		path = home + "/.config/autostart";
		if (Utility.dir_exists(path) == false){
			Utility.create_dir(path);
			debug("Directory Created: " + path);
		}
		
		//load themes --------
		
		reload_themes();
		start_status_thread();
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
	}
	
	public void update_startup_script(){
		string home = Environment.get_home_dir ();
		string startupScript = home + "/conky/conky-startup.sh";
		
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
			txt = txt.replace("{command}", home + "/conky/conky-startup.sh");
			
			Utility.write_file(startupFile, txt);
		}
		else{
			Utility.file_delete(startupFile);			
		}
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
					
					debug("found: %s".printf(filePath));
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
				debug("Font Installed: " + targetFile);
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
	
	public void start_conky()
	{
		Theme.Install();
		
		string cmd = "conky -c \"" + Path + "\"";
		Utility.execute_command_async_batch (cmd); 
		Thread.usleep((ulong)1000000);
		debug("Started: %s".printf(Path));
		
		//set the flag for immediate effect
		//will be updated by the refresh_status() timer
		Enabled = true; 
	}
	
	public void stop_conky()
	{
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
				debug("Stopped: %s: %s".printf(pid, Path));
			}
		}
		
		//set the flag for immediate effect
		//will be updated by the refresh_status() timer
		Enabled = false; 
	}
}
