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
using Json;

using TeeJee.Logging;
using TeeJee.FileSystem;
using TeeJee.DiskPartition;
using TeeJee.JSON;
using TeeJee.ProcessManagement;
using TeeJee.GtkHelper;
using TeeJee.Multimedia;
using TeeJee.System;
using TeeJee.Misc;

public Main App;
public const string AppName = "Conky Manager";
public const string AppVersion = "2.0";
public const string AppAuthor = "Tony George";
public const string AppAuthorEmail = "teejeetech@gmail.com";

const string GETTEXT_PACKAGE = "conky-manager";
const string LOCALE_DIR = "/usr/share/locale";

public class Main : GLib.Object {
	
	public string app_path = "";
	public string share_folder = "";
	public string data_dir = "";
	public string app_conf_path = "";
	
	public Gee.ArrayList<string> search_folders;
	public Gee.ArrayList<ConkyRC> conkyrc_list;
	public Gee.HashMap<string,ConkyRC> conkyrc_map;
	
	public bool is_aborted;
	public string last_cmd;
	
	public int donation_counter = 0;
	public bool donation_disable = false;
	public int donation_reshow_frequency = 3;
	
	public bool capture_background = false;
	public int selected_widget_index = 0;
	
    public static int main(string[] args) {
	
		// set locale
		Intl.setlocale(GLib.LocaleCategory.MESSAGES, "");
		Intl.textdomain(GETTEXT_PACKAGE);
		Intl.bind_textdomain_codeset(GETTEXT_PACKAGE, "utf-8");
		Intl.bindtextdomain(GETTEXT_PACKAGE, LOCALE_DIR);
		
		// initialize
		Gtk.init (ref args);
		App = new Main(args);

		var window = new MainWindow();
		window.destroy.connect(()=>{
			if (!App.donation_disable){
				App.donation_counter++;
				if ((App.donation_counter % App.donation_reshow_frequency) == 0){
					window.show_donation_window(true);
					App.donation_counter = 0;
				}
			}
			App.exit_app();
			Gtk.main_quit();
		});
		window.show_all();

	    Gtk.main();

        return 0;
    }
    
    public Main(string[] args) {
		string home = Environment.get_home_dir();
		app_path = (File.new_for_path (args[0])).get_parent().get_path ();
		share_folder = "/usr/share";
		data_dir = home + "/conky-manager";
		app_conf_path = home + "/.config/conky-manager.json";
		search_folders = new Gee.ArrayList<string>();
		
		//load config ---------
		
		load_app_config();

		//install new theme packs and fonts ---------------
		
		init_directories();
		init_theme_packs();

		//load themes --------
		
		//load_themes_and_widgets();
		//start_status_thread();
	}

	public void save_app_config(){
		var config = new Json.Object();

		config.set_string_member("data_dir", data_dir);
		config.set_string_member("capture_background", capture_background.to_string());
		config.set_string_member("selected_widget_index", selected_widget_index.to_string());
		
		config.set_string_member("donation_counter", donation_counter.to_string());
		config.set_string_member("donation_disable", donation_disable.to_string());

		Json.Array arr = new Json.Array();
		foreach(string path in search_folders){
			arr.add_string_element(path);
		}
		config.set_array_member("search-locations",arr);

		arr = new Json.Array();
		foreach(ConkyRC rc in conkyrc_list){
			arr.add_string_element(rc.path);
		}
		config.set_array_member("conkyrc",arr);
		
		var json = new Json.Generator();
		json.pretty = true;
		json.indent = 2;
		var node = new Json.Node(NodeType.OBJECT);
		node.set_object(config);
		json.set_root(node);
		
		try{
			json.to_file(this.app_conf_path);
		} catch (Error e) {
	        log_error (e.message);
	    }
	    
	    log_msg(_("App config saved") + ": '%s'".printf(app_conf_path));
	}
	
	public void load_app_config(){
		var f = File.new_for_path(app_conf_path);
		if (!f.query_exists()) { return; }
		
		var parser = new Json.Parser();
        try{
			parser.load_from_file(this.app_conf_path);
		} catch (Error e) {
	        log_error (e.message);
	    }
        var node = parser.get_root();
        var config = node.get_object();
        
        string val = json_get_string(config,"data_dir","");
        if (val.length > 0){
			data_dir = val;
		}
		
		capture_background = json_get_bool(config,"capture_background",false);
		selected_widget_index = json_get_int(config,"selected_widget_index",0);
		
		donation_counter = json_get_int(config,"donation_counter",0);
		donation_disable = json_get_bool(config,"donation_disable",false);

		// search folders -------------------
		
		search_folders.clear();
		
		string home = Environment.get_home_dir();
		
		//default locations
		foreach(string path in new string[]{ home + "/.conky", home + "/.Conky", home + "/.config/conky", home + "/.config/Conky"}){
			if (!search_folders.contains(path) && dir_exists(path)){
				search_folders.add(path);
			}
		}

		//add from config file
		if (config.has_member ("search-locations")){
			foreach (Json.Node jnode in config.get_array_member ("search-locations").get_elements()) {
				string path = jnode.get_string();
				if (!search_folders.contains(path) && dir_exists(path)){
					this.search_folders.add(path);
				}
			}
		}

		// widget list ------------------------
		
		clear_themes_and_widgets();
		
		//add from config file
		if (config.has_member ("conkyrc")){
			foreach (Json.Node jnode in config.get_array_member ("conkyrc").get_elements()) {
				string path = jnode.get_string();
				if (!conkyrc_map.has_key(path) && file_exists(path)){
					ConkyRC rc = new ConkyRC(path);
					conkyrc_list.add(rc);
					conkyrc_map[rc.path] = rc;
				}
			}
		}

		log_msg(_("App config loaded") + ": '%s'".printf(this.app_conf_path));
	}
	
	public void init_directories(){
		string path = data_dir;
		string home = Environment.get_home_dir ();
		
		if (dir_exists(path) == false){
			create_dir(path);
			log_debug(_("Directory Created") + ": " + path);
		}

		path = data_dir + "/themes";
		if (dir_exists(path) == false){
			create_dir(path);
			log_debug(_("Directory Created") + ": " + path);
		}
		
		path = home + "/.fonts";
		if (dir_exists(path) == false){
			create_dir(path);
			log_debug(_("Directory Created") + ": " + path);
		}
		
		path = home + "/.config/autostart";
		if (dir_exists(path) == false){
			create_dir(path);
			log_debug(_("Directory Created") + ": " + path);
		}
	}
	
	public void init_theme_packs(){
		string sharePath = "/usr/share/conky-manager/themepacks";
		string config_file = data_dir + "/.themepacks";
		
		//delete config file if no themes found
		if (get_installed_theme_count() == 0) { 
			Posix.system("rm -f \"" + config_file + "\""); 
		}
		
		//create empty config file if missing
		if (file_exists(config_file) == false) { 
			Posix.system("touch \"" + config_file + "\""); 
		}

		//read config file
		string txt = read_file(config_file);
		string[] filenames = txt.split("\n");
			
		try
		{
			FileEnumerator enumerator;
			FileInfo file;
			File fShare = File.parse_name (sharePath);
				
			if (dir_exists(sharePath)){
				enumerator = fShare.enumerate_children (FileAttribute.STANDARD_NAME, 0);
		
				while ((file = enumerator.next_file ()) != null) {
					
					string filePath = sharePath + "/" + file.get_name();
					if (file_exists(filePath) == false) { continue; }
					if (filePath.has_suffix(".cmtp.7z") == false) { continue; }
					
					bool is_installed = false;
					foreach(string filename in filenames){
						if (file.get_name() == filename){
							log_debug(_("Found theme pack [installed]") + ": " + filePath);
							is_installed = true;
							break;
						}
					}
					
					if (!is_installed){
						log_debug("-----------------------------------------------------");
						log_debug(_("Found theme pack [new]") + ": " + filePath);
						install_theme_pack(filePath);
						log_debug("-----------------------------------------------------");
						
						string list = "";
						foreach(string filename in filenames){
							list += filename + "\n";
						}
						list += file.get_name() + "\n";
						write_file(config_file,list);
					}
				} 
			}
		}
        catch(Error e){
	        log_error (e.message);
	    }
	}
	
	public void clear_themes_and_widgets(){
		conkyrc_list = new Gee.ArrayList<ConkyRC>();
		conkyrc_map = new Gee.HashMap<string,ConkyRC>();
	}
	
	public void load_themes_and_widgets() {
		is_aborted = false;
		
		clear_themes_and_widgets();
		
		find_conkyrc_files(data_dir);
		foreach(string path in search_folders){
			if (!is_aborted){
				find_conkyrc_files(path);
			}
		}
		
		CompareFunc<ConkyRC> func = (a, b) => {
			return strcmp(a.name,b.name);
		};
		conkyrc_list.sort(func);

		log_msg(_("Searching for conkyrc files... %d found").printf(conkyrc_list.size));
	}

	public void load_themes_and_widgets_cancel(){
		is_aborted = true;
		command_kill("grep",last_cmd);
	}
	
	public void find_conkyrc_files(string path){
		string std_out = "";
		string std_err = "";
		string cmd = "grep -r \"^[[:blank:]]*TEXT[[:blank:]]*$\" \"%s\"".printf(path);
		last_cmd = cmd;
		int exit_code = execute_command_script_sync(cmd, out std_out, out std_err);
		
		if (exit_code != 0){ 
			//no files found
			return;
		}
		
		string file_path;
		foreach(string line in std_out.split("\n")){
			if (line.index_of(":") > -1){
				file_path = line.split(":")[0].strip();
				if (!conkyrc_map.has_key(file_path)){
					if (file_path.strip().has_suffix("~")){ continue; }
					ConkyRC rc = new ConkyRC(file_path);
					conkyrc_list.add(rc);
					conkyrc_map[rc.path] = rc;
				}
			}
		}
	}

	public int get_installed_theme_count(){
		string path = data_dir + "/themes";
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
		string std_out;
		string std_err;
		int ret_val;
		
		string home = Environment.get_home_dir ();
		string temp_dir = Environment.get_tmp_dir();
		temp_dir = temp_dir + "/" + timestamp2();
		create_dir(temp_dir);
		
		log_debug(_("Installing") + ": " + pkgPath);
		
		cmd = "cd \"" + temp_dir + "\"\n";
		cmd += "7z x \"" + pkgPath + "\">nul\n";
	
		ret_val = execute_command_script_sync(cmd, out std_out, out std_err);
		if (ret_val != 0){
			log_error(_("Failed to unzip files from theme pack"));
			log_error (std_err);
			return -1;
		}

		string temp_dir_themes = temp_dir + "/themes";
		string temp_dir_fonts = temp_dir + "/fonts";
		string temp_dir_home = temp_dir + "/home";
		int count = 0;
	
		//copy themes to <data_dir>/themes

		try
		{	
			if (dir_exists(temp_dir_themes)){

				File f_themes_dir = File.parse_name (temp_dir_themes);
				FileEnumerator enumerator = f_themes_dir.enumerate_children (FileAttribute.STANDARD_NAME, 0);
				FileInfo file;
				
				while ((file = enumerator.next_file ()) != null) {
					string source_dir = temp_dir_themes + "/" + file.get_name();
					string target_dir = data_dir + "/themes/" + file.get_name();

					if (dir_exists(target_dir)) { 
						continue; 
					}
					else{
						count++;
						
						if (!checkOnly){
							//install
							log_debug(_("Theme copied") + ": " + target_dir);
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
			if (dir_exists(temp_dir_fonts)){
				File f_fonts_dir = File.parse_name (temp_dir_fonts);
				FileEnumerator enumerator = f_fonts_dir.enumerate_children (FileAttribute.STANDARD_NAME, 0);
				
				FileInfo file;
				while ((file = enumerator.next_file ()) != null) {
					string source_file = temp_dir_fonts + "/" + file.get_name();
					string target_file = home + "/.fonts/" + file.get_name();
					
					if (file_exists(target_file)) { 
						continue; 
					}
					else{
						if (!checkOnly){
							//install
							log_debug(_("Font copied") + ": " + target_file);
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
			 
			if (dir_exists(temp_dir_home)){
				
				File f_home_dir = File.parse_name (temp_dir_home);
				FileEnumerator enumerator = f_home_dir.enumerate_children (FileAttribute.STANDARD_NAME, 0);
				FileInfo file;
				
				while ((file = enumerator.next_file ()) != null) {
					string dir_name = file.get_name();
					string dir_path = temp_dir_home + "/" + file.get_name();
					
					if ((dir_name.down() == "conky")||(dir_name.down() == ".conky")||(dir_name == ".fonts")){
						if (dir_exists(dir_path)) { 
							log_debug(_("Copy files: ") + home + "/" + dir_name);
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
	
	public void start_status_thread (){
		try {
			Thread.create<void> (status_thread, true);
		} catch (ThreadError e) {
			log_error (e.message);
		}
	}
	
	private void status_thread (){
		while (true){  // loop runs for entire application lifetime
			//refresh_status();
			Thread.usleep((ulong)3000000);
		}
	}
	
	private void exit_app(){
		update_startup_script();
		
		save_app_config();
		
		if (check_startup()){
			autostart(true); //overwrite the startup entry
		}
	}
	
	public void run_startup_script(){
		execute_command_sync("sh \"" + data_dir + "/conky-startup.sh\"");
		Posix.usleep(500000);//microseconds
		//refresh_status();
	}
	
	public void update_startup_script(){
		string startupScript = data_dir + "/conky-startup.sh";
		
		string txt = "killall conky\n";
		foreach(ConkyRC conf in conkyrc_list){
			if (conf.enabled){
				txt += "cd \"" + conf.dir + "\"\n";
				txt += "conky -c \"" + conf.path + "\" &\n";
			}
		}

		write_file(startupScript, txt);
	}
	
	public bool check_startup(){
		string home = Environment.get_home_dir ();
		string startupFile = home + "/.config/autostart/conky.desktop";
		return file_exists(startupFile);	
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
			txt = txt.replace("{command}", "sh \"" + data_dir + "/conky-startup.sh\"");
			
			write_file(startupFile, txt);
		}
		else{
			file_delete(startupFile);			
		}
	}
	
	public void kill_all_conky(){
		Posix.system("killall conky");
		//refresh_status();
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
		temp_dir = temp_dir + "/" + timestamp2();
		create_dir(temp_dir);
		string py_file = temp_dir + "/minimize.py";
		
        write_file(py_file, txt);
	    chmod (py_file, "u+x");

        Posix.system(py_file);
	}
}

public class ConkyRC : GLib.Object {
	//public ConkyTheme theme;
	public string name = "";
	public string base_name = "";
	public string dir = "";
	public string path = "";
	public string image_path = "";
	public bool enabled = false;
	public string text = "";
	
	private Regex rex_conky_win;
	private MatchInfo match;
	
	private string err_line;
	private string out_line;
	private DataInputStream dis_out;
	private DataInputStream dis_err;
	private bool is_running = false;
	private int wait_interval = 0;
	private uint timer_preview;
	
	public ConkyRC(string rc_file_path) {
		path = rc_file_path;
		
		var f = File.new_for_path (rc_file_path);
		name = path.replace(Environment.get_home_dir(),"~");
		base_name = f.get_basename();
		dir = f.get_parent().get_path();

		image_path = dir + "/" + base_name + ".png";

		try{
			rex_conky_win = new Regex("""\(0x([0-9a-zA-Z]*)\)""");
		}
		catch (Error e) {
			log_error (e.message);
		}
	}
	
	public void start_conky(){
		string cmd;

		if (enabled){
			stop_conky();
		}
		
		//Theme.install();
		
		cmd = "cd \"" + dir + "\"\n";
		cmd += "conky -c \"" + path + "\"\n";

		execute_command_script_async(cmd);

		Thread.usleep((ulong)1000000);
		log_debug(_("Started") + ": " + path);
		
		//set the flag for immediate effect
		//will be updated by the refresh_status() timer
		enabled = true; 
	}
	
	public bool stop_conky(){
		
		//Note: There may be more than one running instance of the same config
		//We need to kill all instances
		
		string cmd = "conky -c " + path; //without double-quotes
		string txt = execute_command_sync_get_output ("ps w -C conky");
		//use 'ps ew -C conky' for all users
		
		string pid = "";
		foreach(string line in txt.split("\n")){
			if (line.index_of(cmd) != -1){
				pid = line.strip().split(" ")[0];
				Posix.kill ((Pid) int.parse(pid), 15);
				log_debug(_("Stopped") + ": [PID=" + pid + "] " + path);
			}
		}
		
		//set the flag for immediate effect
		//will be updated by the refresh_status() timer
		enabled = false; 
		
		return true;
	}
	
	public void read_file(){
		log_debug("Read config file from disk");
		this.text = TeeJee.FileSystem.read_file(this.path);
	}
	
	public void save_file(){
		log_debug("Saved config file changes to disk");
		write_file(this.path, text);
	}

	public void save_file_temp(){
		write_file(this.path + "~temp~", text);
	}
	
	public void delete_file_temp(){
		file_delete(this.path + "~temp~");
	}
	
	public bool generate_preview(){
		stop_conky();
		read_file();
		if (App.capture_background){
			transparency = "pseudo";
		}
		else{
			transparency = "opaque";
		}
		delete_file_temp();
		save_file_temp();
		
		read_file();
		wait_interval = 3;
		foreach(string line in text.split("\n")){
			if (line.contains("lua_load") && !(line.strip().has_prefix("#"))){
				wait_interval = 10;
				break;
			}
		}
		
		try {
			is_running = true;
			Thread.create<void> (generate_preview_thread, true);
		} catch (ThreadError e) {
			is_running = false;
			log_error (e.message);
		}

		while (is_running){
			Thread.usleep ((ulong) 200000);
			gtk_do_events();
		}
			
		if ((image_path.length > 0) && (file_exists(image_path))){
			return true;
		}
		else{
			return false;
		}
	}
	
	public void generate_preview_thread (){
		string cmd = "cd \"" + dir + "\"\n";
		cmd += "conky -c \"" + path + "~temp~\" 2>&1 \n";

		string[] argv = new string[1];
		argv[0] = create_temp_bash_script(cmd);
		
		Pid child_pid;
		int input_fd;
		int output_fd;
		int error_fd;

		try {
			//execute script file
			Process.spawn_async_with_pipes(
			    null, //working dir
			    argv, //argv
			    null, //environment
			    SpawnFlags.SEARCH_PATH,
			    null,   // child_setup
			    out child_pid,
			    out input_fd,
			    out output_fd,
			    out error_fd);
			
			is_running = true;
			
			timer_preview = Timeout.add (10 * 1000, stop_conky);
			
			//create stream readers
			UnixInputStream uis_out = new UnixInputStream(output_fd, false);
			UnixInputStream uis_err = new UnixInputStream(error_fd, false);
			dis_out = new DataInputStream(uis_out);
			dis_err = new DataInputStream(uis_err);
			dis_out.newline_type = DataStreamNewlineType.ANY;
			dis_err.newline_type = DataStreamNewlineType.ANY;
			
        	try {
				//start thread for reading output stream
			    Thread.create<void> (conky_read_output_line, true);
		    } catch (Error e) {
		        log_error (e.message);
		    }
		    
		    try {
				//start thread for reading error stream
			    Thread.create<void> (conky_read_error_line, true);
		    } catch (Error e) {
		        log_error (e.message);
		    }
		}
		catch (Error e) {
			log_error (e.message);
		}
	}

	private void conky_read_error_line(){
		try{
			err_line = dis_err.read_line (null);
		    while (err_line != null) {
				//do nothing
		        err_line = dis_err.read_line (null); //read next
			}
		}
		catch (Error e) {
			log_error (e.message);
		}	
	}
	
	private void conky_read_output_line(){
		try{
			out_line = dis_out.read_line (null);
		    while (out_line != null) {
				if (rex_conky_win.match (out_line, 0, out match)){
					Thread.usleep ((ulong) wait_interval * 1000000);
					string win_id = match.fetch(1).strip();
					string cmd = "import -window 0x%s '%s'".printf(win_id,image_path);
					execute_command_sync(cmd);
					Thread.usleep ((ulong) 200000);
					if (timer_preview > 0){
						Source.remove(timer_preview);
						timer_preview = 0;
					}
					stop_conky();
				}
				out_line = dis_out.read_line (null);  //read next
			}

			is_running = false;
			delete_file_temp();
		}
		catch (Error e) {
			log_error (e.message);
		}	
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

			log_debug("Get: alignment " + s);

			return s;
		}
		set
		{
			string newLine = "alignment " + value;
			set_value("alignment", newLine);
			log_debug("Set: alignment " + value);
		}
	}
	
	public string gap_x{
		owned get{
			string s = get_value("gap_x");
			if (s == "") { s = "0"; }
			log_debug("Get: gap_x " + s);
			return s;
		}
		set
		{
			string newLine = "gap_x " + value;
			set_value("gap_x", newLine);
			log_debug("Set: gap_x " + value);
		}
	}
	
	public string gap_y{
		owned get{
			string s = get_value("gap_y");
			if (s == "") { s = "0"; }
			log_debug("Get: gap_y " + s);
			return s;
		}
		set
		{
			string newLine = "gap_y " + value;
			set_value("gap_y", newLine);
			log_debug("Set: gap_y " + value);
		}
	}
	
	public string own_window_transparent{
		owned get{
			string s = get_value("own_window_transparent");
			if (s == "") { s = ""; }
			log_debug("Get: own_window_transparent " + s);
			return s;
		}
		set
		{
			string newLine = "own_window_transparent " + value;
			set_value("own_window_transparent", newLine);
			log_debug("Set: own_window_transparent " + value);
		}
	}
	
	public string own_window_argb_visual{
		owned get{
			string s = get_value("own_window_argb_visual");
			if (s == "") { s = ""; }
			log_debug("Get: own_window_argb_visual " + s);
			return s;
		}
		set
		{
			string newLine = "own_window_argb_visual " + value;
			set_value("own_window_argb_visual", newLine);
			log_debug("Set: own_window_argb_visual " + value);
		}
	}
	
	public string own_window_argb_value{
		owned get{
			string s = get_value("own_window_argb_value");
			if (s == "") { s = ""; }
			log_debug("Get: own_window_argb_value " + s);
			return s;
		}
		set
		{
			string newLine = "own_window_argb_value " + value;
			set_value("own_window_argb_value", newLine);
			log_debug("Set: own_window_argb_value " + value);
		}
	}
	
	public string own_window_colour{
		owned get{
			string s = get_value("own_window_colour");
			if (s == "") { s = "000000"; }
			log_debug("Get: own_window_colour " + s);
			return s.up();
		}
		set{
			string newLine = "own_window_colour " + value.up();
			set_value("own_window_colour", newLine);
			log_debug("Set: own_window_colour " + value.up());
		}
	}
	
	public string transparency{
		owned get{
			string s = "trans";

			if(own_window_transparent == "yes"){
				if(own_window_argb_visual == "yes"){
					//own_window_argb_value, if present, will be ignored by Conky
					s = "trans";
				}
				else if (own_window_argb_visual == "no"){
					s = "pseudo";
				}
				else{
					s = "pseudo";
				}
			}
			else if (own_window_transparent == "no"){
				if(own_window_argb_visual == "yes"){
					if (own_window_argb_value == "0"){
						s = "trans";
					}
					else if (own_window_argb_value == "255"){
						s = "opaque";
					}
					else{
						s = "semi";
					}
				}
				else if (own_window_argb_visual == "no"){
					s = "opaque";
				}
				else{
					s = "opaque";
				}
			}
			else{
				s = "opaque";
			}
			
			log_debug("Get: transparency " + s);
			
			return s;
		}
		set{
			switch (value.down()){
				case "opaque":
					own_window_transparent = "no";
					own_window_argb_visual = "no";
					break;
				case "trans":
					own_window_transparent = "yes";
					own_window_argb_visual = "yes";
					own_window_argb_value = "0";
					break;
				case "pseudo":
					own_window_transparent = "yes";
					own_window_argb_visual = "no";
					break;
				case "semi":
				default:
					own_window_transparent = "no";
					own_window_argb_visual = "yes";
					break;
			}
		
			log_debug("Set: transparency " + value.down());
		}
	}
	
	public string minimum_size{
		owned get{
			string s = get_value("minimum_size");
			if ((s == "")||(s.split(" ").length != 2)) { s = "0 0"; }
			log_debug("Get: minimum_size " + s);
			return s;
		}
		set
		{
			string newLine = "minimum_size " + value;
			set_value("minimum_size", newLine);
			log_debug("Set: minimum_size " + value);
		}
	}
	
	public int height_padding{
		get{
			string[] arr = this.text.split("\n");
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
			
			log_debug("Get: height_padding " + count.to_string());
			
			return count;
		}
		set
		{
			string newText = "";
			string[] arr = this.text.split("\n");
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
			
			log_debug("Set: height_padding " + value.to_string());
			
			this.text = newText;
		}
	}
	
	public string time_format{
		owned get{
			string val = "";
			
			if (search("""\${(time|TIME) [^}]*H[^}]*}""") != ""){
				val = "24";
				log_debug("Get: time format = 24-hour");
			}
			else if (search("""\${(time|TIME) [^}]*I[^}]*}""") != ""){
				val = "12";
				log_debug("Get: time format = 12-hour");
			}

			return val;
		}
		set
		{
			if (value == "") { return; }
			
			switch(value){
				case "12":
					if (replace("""\${(time|TIME) [^}]*(H)[^}]*}""", 2, "I")){
						log_debug("Set: time format = 12-hour");
					}
					break;
				case "24":
					if (replace("""\${(time|TIME) [^}]*(I)[^}]*}""", 2, "H")){
						log_debug("Set: time format = 24-hour");
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
				log_debug("Get: network interface = " + net);
				return net;
			}
			
			net = search(var2, 2);
			
			if (net != ""){
				log_debug("Get: network interface = " + net);
				return net;
			}
			
			net = search(var3, 2);
			
			if (net != ""){
				log_debug("Get: network interface = " + net);
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
					log_debug("Set: network interface = " + value);
				}
			}
			
			net = search(var2, 2);
			
			if (net != ""){
				if (replace(var2, 2, value)){
					log_debug("Set: network interface = " + value);
				}
			}
			
			net = search(var3, 2);
			
			if (net != ""){
				if (replace(var3, 2, value)){
					log_debug("Set: network interface = " + value);
				}
			}
		}
	}
	
	public string get_value(string param){
		foreach(string line in this.text.split("\n")){
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
		
		foreach(string line in this.text.split("\n")){
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
		
		this.text = newText;
	}
	
	public string search(string search_string, int bracket_num = 0){
		foreach(string line in this.text.split("\n")){
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
		
		foreach(string line in this.text.split("\n")){
			try{
				Regex regx = new Regex(search_string);
				MatchInfo match;
				if (regx.match(line, 0, out match)){
					
					bool matchExists = true;
					new_line = line;
					
					while (matchExists){
						old_match = match.fetch(0);
						new_match = old_match.replace(match.fetch(bracket_num),replace_string);
						//log_debug("old_match=%s\nnew_match=%s\n".printf(old_match,new_match));
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
		
		this.text = new_text;
		
		return found;
	}
}
