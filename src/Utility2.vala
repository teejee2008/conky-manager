/*
 * Utility.vala
 * 
 * Copyright 2013 Tony George <teejee2008@gmail.com>
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

/*
public Main App;
public const string AppName = "Conky Manager";
public const string AppVersion = "1.0";
public const string AppAuthor = "Tony George";
public const string AppAuthorEmail = "teejee2008@gmail.com";
public const bool LogTimestamp = false;
public const bool UseConsoleColors = true;
public const bool EnableDebuggingMessages = true;
*/

using Gtk;

public void log_msg (string message, bool highlight = false)
{
	string msg = "";
	
	if (highlight && UseConsoleColors){
		msg += "\033[1;38;5;34m";
	}
	
	if (LogTimestamp){
		msg += "[" + Utility.timestamp() +  "] ";
	}
	
	msg += message;
	
	if (highlight && UseConsoleColors){
		msg += "\033[0m";
	}
	
	msg += "\n";
	
	stdout.printf (msg);
}

public void log_error (string message, bool highlight = false)
{
	string msg = "";
	
	if (highlight && UseConsoleColors){
		msg += "\033[1;38;5;160m";
	}
	
	if (LogTimestamp){
		msg += "[" + Utility.timestamp() +  "] ";
	}
	
	msg += "Error: " + message;
	
	if (highlight && UseConsoleColors){
		msg += "\033[0m";
	}
	
	msg += "\n";
	
	stderr.printf (msg);
}

public void debug (string message)
{
	if (EnableDebuggingMessages){
		log_msg (message);
	}
}

namespace Utility 
{
	public void messagebox_show(string title, string message, bool is_error = false)
	{
		Gtk.MessageType type = Gtk.MessageType.INFO;
		
		if (is_error)
			type = Gtk.MessageType.ERROR;
			
		var dialog = new Gtk.MessageDialog(null,Gtk.DialogFlags.MODAL, type, Gtk.ButtonsType.OK, message);
		dialog.set_title(title);
		dialog.run();
		dialog.destroy();
	}	
	
	public void file_delete(string filePath)
	{
		try {
			var file = File.new_for_path (filePath);
			if (file.query_exists ()) { 
				file.delete (); 
			}
		} catch (Error e) {
	        log_error (e.message);
	    }
	}
	
	public string timestamp2 ()
	{
		return "%ld".printf((long) time_t ());
	}
	
	public string timestamp ()
	{
		Time t = Time.local (time_t ());
		return t.format ("%H:%M:%S");
	}
	
	public string format_file_size (int64 size)
	{
		return "%0.1f MB".printf (size / (1024.0 * 1024));
	}
	
	public string format_duration (long millis)
	{
	    double time = millis / 1000.0; // time in seconds

	    double hr = Math.floor(time / (60.0 * 60));
	    time = time - (hr * 60 * 60);
	    double min = Math.floor(time / 60.0);
	    time = time - (min * 60);
	    double sec = Math.floor(time);
	    
        return "%02.0lf:%02.0lf:%02.0lf".printf (hr, min, sec);
	}
	
	public double parse_time (string time)
	{
		string[] arr = time.split (":");
		double millis = 0;
		if (arr.length >= 3){
			millis += double.parse(arr[0]) * 60 * 60;
			millis += double.parse(arr[1]) * 60;
			millis += double.parse(arr[2]);
		}
		return millis;
	}
	
	public long get_file_duration(string filePath)
	{
		string output = "0";
		
		try {
			Process.spawn_command_line_sync("mediainfo \"--Inform=General;%Duration%\" " + double_quote (filePath), out output);
		}
		catch(Error e){
	        log_error (e.message);
	    }
	    
		return long.parse(output);
	}
	
	public string get_file_crop_params (string filePath)
	{
		string output = "";
		string error = "";
		
		try {
			Process.spawn_command_line_sync("avconv -i " + double_quote (filePath) + " -vf cropdetect=30 -ss 5 -t 5 -f matroska -an -y /dev/null", out output, out error);
		}
		catch(Error e){
	        log_error (e.message);
	    }
	    	    
	    int w=0,h=0,x=10000,y=10000;
		int num=0;
		string key,val;
	    string[] arr;
	    
	    foreach (string line in error.split ("\n")){
			if (line == null) { continue; }
			if (line.index_of ("crop=") == -1) { continue; }

			foreach (string part in line.split (" ")){
				if (part == null || part.length == 0) { continue; }
				
				arr = part.split (":");
				if (arr.length != 2) { continue; }
				
				key = arr[0].strip ();
				val = arr[1].strip ();
				
				switch (key){
					case "x":
						num = int.parse (arr[1]);
						if (num < x) { x = num; }
						break;
					case "y":
						num = int.parse (arr[1]);
						if (num < y) { y = num; }
						break;
					case "w":
						num = int.parse (arr[1]);
						if (num > w) { w = num; }
						break;
					case "h":
						num = int.parse (arr[1]);
						if (num > h) { h = num; }
						break;
				}
			}
		}
		
		if (x == 10000 || y == 10000)
			return "%i:%i:%i:%i".printf(0,0,0,0);
		else 
			return "%i:%i:%i:%i".printf(w,h,x,y);
	}
	
	public string get_mediainfo (string filePath)
	{
		string output = "";
		
		try {
			Process.spawn_command_line_sync("mediainfo " + double_quote (filePath), out output);
		}
		catch(Error e){
	        log_error (e.message);
	    }
	    
		return output;
	}
	
	public long[] get_process_children (Pid parentPid)
	{
		string output;
		
		try {
			Process.spawn_command_line_sync("ps --ppid " + parentPid.to_string(), out output);
		}
		catch(Error e){
	        log_error (e.message);
	    }
			
		long pid;
		long[] procList = {};
		string[] arr;
		
		foreach (string line in output.split ("\n")){
			arr = line.strip().split (" ");
			if (arr.length < 1) { continue; }
			
			pid = 0;
			pid = long.parse (arr[0]);
			
			if (pid != 0){
				procList += pid;
			}
		}
		return procList;
	}
	
	public void process_kill(Pid process_pid, bool killChildren = true)
	{
		long[] child_pids = get_process_children (process_pid);
		Posix.kill (process_pid, 15);
		
		if (killChildren){
			Pid childPid;
			foreach (long pid in child_pids){
				childPid = (Pid) pid;
				Posix.kill (childPid, 15);
			}
		}
	}
	
	public void process_set_priority (Pid procID, int prio)
	{
		if (Posix.getpriority (Posix.PRIO_PROCESS, procID) != prio)
			Posix.setpriority (Posix.PRIO_PROCESS, procID, prio);
	}
	
	public int process_get_priority (Pid procID)
	{
		return Posix.getpriority (Posix.PRIO_PROCESS, procID);
	}
	
	public void process_set_priority_normal (Pid procID)
	{
		process_set_priority (procID, 0);
	}
	
	public void process_set_priority_low (Pid procID)
	{
		process_set_priority (procID, 5);
	}
	
	public bool file_exists (string filePath)
	{
		return ( FileUtils.test(filePath, GLib.FileTest.EXISTS) && FileUtils.test(filePath, GLib.FileTest.IS_REGULAR));
	}
	
	public bool dir_exists (string filePath)
	{
		return ( FileUtils.test(filePath, GLib.FileTest.EXISTS) && FileUtils.test(filePath, GLib.FileTest.IS_DIR));
	}
	
	public bool create_dir (string filePath)
	{
		try{
			var dir = File.parse_name (filePath);
			if (dir.query_exists () == false) {
				dir.make_directory (null);
			}
			return true;
		}
		catch (Error e) { 
			log_error (e.message); 
			return false;
		}
	}
	
	public bool move_file (string sourcePath, string destPath)
	{
		try{
			File fromFile = File.new_for_path (sourcePath);
			File toFile = File.new_for_path (destPath);
			fromFile.move (toFile, FileCopyFlags.NONE);
			return true;
		}
		catch (Error e) { 
			log_error (e.message); 
			return false;
		}
	}
	
	public bool copy_file (string sourcePath, string destPath)
	{
		try{
			File fromFile = File.new_for_path (sourcePath);
			File toFile = File.new_for_path (destPath);
			fromFile.copy (toFile, FileCopyFlags.NONE);
			return true;
		}
		catch (Error e) { 
			log_error (e.message); 
			return false;
		}
	}
	
	public string resolve_relative_path (string filePath)
	{
		string filePath2 = filePath;
		if (filePath2.has_prefix ("~")){
			filePath2 = Environment.get_home_dir () + "/" + filePath2[2:filePath2.length];
		}
		
		try {
			string output = "";
			Process.spawn_command_line_sync("realpath " + double_quote (filePath2), out output);
			output = output.strip ();
			if (FileUtils.test(output, GLib.FileTest.EXISTS)){
				return output;
			}
		}
		catch(Error e){
	        log_error (e.message);
	    }
	    
	    return filePath2;
	}
	
	public bool user_is_admin ()
	{
		try{
			// create a process
			string[] argv = { "sleep", "10" };
			Pid procId;
			Process.spawn_async(null, argv, null, SpawnFlags.SEARCH_PATH, null, out procId); 
			
			// try changing the priority
			Posix.setpriority (Posix.PRIO_PROCESS, procId, -5);
			
			// check if priority was changed successfully
			if (Posix.getpriority (Posix.PRIO_PROCESS, procId) == -5)
				return true;
			else
				return false;
		} 
		catch (Error e) { 
			log_error (e.message); 
			return false;
		}
	}
	
	public int get_pid_by_name (string name)
	{
		try{
			string output = "";
			Process.spawn_command_line_sync("pidof " + double_quote (name), out output);
			if (output != null){
				string[] arr = output.split ("\n");
				if (arr.length > 0){
					return int.parse (arr[0]);
				}
			}
		} 
		catch (Error e) { 
			log_error (e.message); 
		}
		
		return -1;
	}
	
	public bool shutdown ()
	{
		try{
			string[] argv = { "shutdown", "-h", "now" };
			Pid procId;
			Process.spawn_async(null, argv, null, SpawnFlags.SEARCH_PATH, null, out procId); 
			return true;
		} 
		catch (Error e) { 
			log_error (e.message); 
			return false;
		}
	}
	
	public string double_quote (string txt)
	{
		return "\"" + txt.replace ("\"","\\\"") + "\"";
	}

	public int execute_command_sync (string cmd)
	{
		try {
			int exitCode;
			Process.spawn_command_line_sync(cmd, null, null, out exitCode);
	        return exitCode;
		}
		catch (Error e){
	        log_error (e.message);
	        return -1;
	    }
	}
	
	public string execute_command_sync_get_output (string cmd)
	{
		try {
			int exitCode;
			string std_out;
			Process.spawn_command_line_sync(cmd, out std_out, null, out exitCode);
	        return std_out;
		}
		catch (Error e){
	        log_error (e.message);
	        return "";
	    }
	}

	public bool execute_command_async_batch (string cmd)
	{
		try {
			
			string scriptfile = create_temp_bash_script ("#!/bin/bash\n" + cmd);
			
			string[] argv = new string[1];
			argv[0] = scriptfile;
			
			Pid child_pid;
			Process.spawn_async_with_pipes(
			    null, //working dir
			    argv, //argv
			    null, //environment
			    SpawnFlags.SEARCH_PATH,
			    null,
			    out child_pid);
			return true;
		}
		catch (Error e){
	        log_error (e.message);
	        return false;
	    }
	}
	
	public bool execute_command_async (string[] args)
	{
		try {
			Process.spawn_async(null, args, null, SpawnFlags.SEARCH_PATH, null, null);
			return true;
		}
		catch (Error e){
			log_error (e.message);
			return false;
		}
	}
	
	public bool execute_command_sync_batch (string cmd)
	{
		try {
			
			string scriptfile = create_temp_bash_script ("#!/bin/bash\n" + cmd);
			
			string[] argv = new string[1];
			argv[0] = scriptfile;
			
			Process.spawn_sync(
			    null, //working dir
			    argv, //argv
			    null, //environment
			    SpawnFlags.SEARCH_PATH, //flags
			    null, //child setup
			    null, //stdOutput
			    null, //stdError
			    null  //exitCode
			    ); 
			    
			return true;
		}
		catch (Error e){
	        log_error (e.message);
	        return false;
	    }
	}
	
	public string? create_temp_bash_script (string cmd)
	{
		string script_path = Environment.get_tmp_dir () + "/" + timestamp2() + ".sh";

		if (write_file (script_path, cmd)){  // create file
			chmod (script_path, "u+x");      // set execute permission
			return script_path;
		}
		else{
			return null;
		}
	}
	
	public string? read_file (string file_path)
	{
		string txt;
		size_t size;
		
		try{
			GLib.FileUtils.get_contents (file_path, out txt, out size);
			return txt;	
		}
		catch (Error e){
	        log_error (e.message);
	    }
	    
	    return null;
	}
	
	public bool write_file (string file_path, string contents)
	{
		try{
			var file = File.new_for_path (file_path);
			if (file.query_exists ()) { file.delete (); }
			var file_stream = file.create (FileCreateFlags.REPLACE_DESTINATION);
			var data_stream = new DataOutputStream (file_stream);
			data_stream.put_string (contents);
			data_stream.close();
			return true;
		}
		catch (Error e) {
	        log_error (e.message);
	        return false;
	    } 
	}
	
	public bool execute_command_script_in_terminal_sync (string script)
	{
		try {
			
			string[] argv = new string[3];
			argv[0] = "x-terminal-emulator";
			argv[1] = "-e";
			argv[2] = script;
		
			Process.spawn_sync (
			    Environment.get_tmp_dir (), //working dir
			    argv, //argv
			    null, //environment
			    SpawnFlags.SEARCH_PATH,
			    null   // child_setup
			    );
			    
			return true;
		}
		catch (Error e){
	        log_error (e.message);
	        return false;
	    }
	}
	
	public void setting_read (string section, string key)
	{
		//string config_file = get_app_dir () + "/config";
		//string txt = read_file (config_file);
		
		//string section
	}
	
	public void setting_write (string section, string key)
	{
		
	}
	
	public string get_app_path ()
	{
		try{
			return GLib.FileUtils.read_link ("/proc/self/exe");	
		}
		catch (Error e){
	        log_error (e.message);
	        return "";
	    }
	}
	
	public string get_app_dir ()
	{
		try{
			return (File.new_for_path (GLib.FileUtils.read_link ("/proc/self/exe"))).get_parent ().get_path ();	
		}
		catch (Error e){
	        log_error (e.message);
	        return "";
	    }
	}
	
	public int exo_open_folder (string txt)
	{
		string path;
		
		path = get_cmd_path ("exo-open");
		if ((path != null)&&(path != "")){
			return execute_command_sync ("exo-open " + double_quote (txt));
		}

		path = get_cmd_path ("nemo");
		if ((path != null)&&(path != "")){
			return execute_command_sync ("nemo " + double_quote (txt));
		}
		
		path = get_cmd_path ("nautilus");
		if ((path != null)&&(path != "")){
			return execute_command_sync ("nautilus " + double_quote (txt));
		}
		
		path = get_cmd_path ("thunar");
		if ((path != null)&&(path != "")){
			return execute_command_sync ("thunar " + double_quote (txt));
		}

		return -1;
	}

	public int exo_open_textfile (string txt)
	{
		string path;
		
		path = get_cmd_path ("exo-open");
		if ((path != null)&&(path != "")){
			return execute_command_sync ("exo-open " + double_quote (txt));
		}

		path = get_cmd_path ("gedit");
		if ((path != null)&&(path != "")){
			return execute_command_sync ("gedit --new-document " + double_quote (txt));
		}

		return -1;
	}
	
	public int chmod (string file, string permission)
	{
		return execute_command_sync ("chmod " + permission + " " + double_quote (file));
	}
	
	public int process_pause (Pid procID)
	{
		return execute_command_sync ("kill -STOP " + procID.to_string());
	}
	
	public int process_resume (Pid procID)
	{
		return execute_command_sync ("kill -CONT " + procID.to_string());
	}

	public int notify_send (string title, string message, int durationMillis, string urgency)
	{
		string s = "notify-send -t %d -u %s -i %s \"%s\" \"%s\"".printf(durationMillis, urgency, Gtk.Stock.INFO, title, message);
		return execute_command_sync (s);
	}
	
	public int rsync (string sourceDirectory, string destDirectory, bool updateExisting, bool deleteExtra)
	{
		string cmd = "rsync --recursive --perms --chmod=a=rwx";
		cmd += updateExisting ? "" : " --ignore-existing";
		cmd += deleteExtra ? " --delete" : "";
		cmd += " " + double_quote(sourceDirectory + "//");
		cmd += " " + double_quote(destDirectory);
		return execute_command_sync (cmd);
	}
	

	
	public string get_cmd_path (string cmd)
	{
		try {
			int exitCode; 
			string stdout, stderr;
			Process.spawn_command_line_sync("which " + cmd, out stdout, out stderr, out exitCode);
	        return stdout;
		}
		catch (Error e){
	        log_error (e.message);
	        return "";
	    }
	}
	
	public void do_events ()
    {
		while(Gtk.events_pending ())
			Gtk.main_iteration ();
	}

	public bool gtk_combobox_set_value (ComboBox combo, int index, string val)
	{
		TreeIter iter;
		string comboVal;
		TreeModel model = (TreeModel) combo.model;
		
		bool iterExists = model.get_iter_first (out iter);
		while (iterExists){
			model.get(iter, 1, out comboVal);
			if (comboVal == val){
				combo.set_active_iter(iter);
				return true;
			}
			iterExists = model.iter_next (ref iter);
		} 
		
		return false;
	}
	
	public string gtk_combobox_get_value (ComboBox combo, int index, string default_value)
	{
		if (combo.model == null) { return default_value; }
		if (combo.active < 0) { return default_value; }
		
		TreeIter iter;
		string val = "";
		combo.get_active_iter (out iter);
		TreeModel model = (TreeModel) combo.model;
		model.get(iter, index, out val);
			
		return val;
	}
	
	public static string rgba_to_hex (Gdk.RGBA color, bool alpha = false, bool prefix_hash = true){
		string hex = "";
		
		if (alpha){
			hex = "%02x%02x%02x%02x".printf((uint)(Math.round(color.red*255)),
									(uint)(Math.round(color.green*255)),
									(uint)(Math.round(color.blue*255)),
									(uint)(Math.round(color.alpha*255)))
									.up();
		}
		else {														
			hex = "%02x%02x%02x".printf((uint)(Math.round(color.red*255)),
									(uint)(Math.round(color.green*255)),
									(uint)(Math.round(color.blue*255)))
									.up();
		}	
		
		if (prefix_hash){
			hex = "#" + hex;
		}	
		
		return hex;													
	}
	
	public static Gdk.RGBA hex_to_rgba (string hex_color){
		string hex = hex_color.strip().down();
		if (hex.has_prefix("#") == false){
			hex = "#" + hex;
		}
		
		Gdk.RGBA color = Gdk.RGBA();
		if(color.parse(hex) == false){
			color.parse("#000000");
		}
		color.alpha = 255;
		
		return color;
	}
	
	public static Gee.ArrayList<UsbDevice> get_usb_device_list()
	{
		Gee.ArrayList<UsbDevice> list = new Gee.ArrayList<UsbDevice>();
		
		//
		
		try {
			var dir = File.new_for_path ("/dev/disk/by-id");
			var enumerator = dir.enumerate_children (FileAttribute.STANDARD_NAME, 0);

			FileInfo file_info;
			while ((file_info = enumerator.next_file ()) != null) {
				if (file_info.get_name().index_of("usb") > -1){
					UsbDevice usb = new UsbDevice();
					usb.DevName = Utility.resolve_relative_path("/dev/disk/by-id/" + file_info.get_name());
					
					string s = Utility.execute_command_sync_get_output("mount|grep " + usb.DevName);
					debug(s);
					//debug("%s\n".printf(file_info.get_name()));
					//stdout.printf ("%s, %s\n",file_info.get_name (), );
					if (file_info.get_is_symlink ()){
						
					}
				}
			}
		} 
		catch (Error e) {
			stderr.printf ("Error: %s\n", e.message);
		}
    
		//foreach (string line in s.split("\n"))
		{
			//int index = line.index_of("../../");
			//if (index == -1) { continue; }
			//string name = line[index+6:line.length];
			//list += name + ";";
			//debug(name);
		}
		
		
		return list;
	}
}

public class UsbDevice : GLib.Object
{
	public string DevName = "";
	public string MountPoint = "";
	public string Type = "";

	public int format_fat32()
	{
		return 0;
	}
}

public class CellRendererProgress2 : Gtk.CellRendererProgress
{
	public override void render (Cairo.Context cr, Gtk.Widget widget, Gdk.Rectangle background_area, Gdk.Rectangle cell_area, Gtk.CellRendererState flags) 
	{
		
		if (text == "--") 
			return;
			
        int diff = (int) ((cell_area.height - height)/2);
        
        // Apply the new height into the bar, and center vertically:
        Gdk.Rectangle new_area = Gdk.Rectangle() ;
        new_area.x = cell_area.x;
        new_area.y = cell_area.y + diff;
        new_area.width = width - 5;
        new_area.height = height;
        
        base.render(cr, widget, background_area, new_area, flags);
	}
} 
