/*
 * MainWindow.vala
 * 
 * Copyright 2012 Tony George <teejee2008@gmail.com>
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
 
using Gtk;

using TeeJee.Logging;
using TeeJee.FileSystem;
using TeeJee.DiskPartition;
using TeeJee.JSON;
using TeeJee.ProcessManagement;
using TeeJee.GtkHelper;
using TeeJee.Multimedia;
using TeeJee.System;
using TeeJee.Misc;

public class MainWindow : Window {
	
	private ComboBox cmb_type;
	private Image img_preview;
	private Box vbox_main;
	private Box vbox_status;
	private Box hbox_widget;
	
	//toolbar
	private Toolbar toolbar;
	private ToolButton btn_prev;
	private ToolButton btn_next;
	private ToolButton btn_start;
	private ToolButton btn_stop;
	private ToolButton btn_edit;
	private ToolButton btn_edit_gui;
	private ToolButton btn_scan;
	private ToolButton btn_generate_preview;
	private ToolButton btn_generate_preview_all;
	private ToolButton btn_kill_all;
	private ToolButton btn_settings;
	private ToolButton btn_donate;
	private ToolButton btn_about;
	private Box hbox_progressbar;
	private ProgressBar progressbar;
	private Label lbl_status;
	private Label lbl_widget_name;
	private Button btn_cancel_action;
	private ScrolledWindow sw_preview;
	private EventBox ebox_preview;
	
	//window dimensions
	private int def_width = 600;
	private int def_height = 500;
	private bool is_running;
	private bool is_aborted;
	private ConkyRC current_rc;
	private uint timer_init;
	
	public MainWindow() {
		title = AppName + " v" + AppVersion;// + " by " + AppAuthor + " (" + "teejeetech.blogspot.in" + ")";
        window_position = WindowPosition.CENTER;
        modal = true;
        set_default_size(def_width, def_height);

        //set app icon
		try{
			this.icon = new Gdk.Pixbuf.from_file (App.share_folder + """/pixmaps/conky-manager.png""");
		}
        catch(Error e){
	        log_error (e.message);
	    }

		//vbox_main
        vbox_main = new Box (Orientation.VERTICAL, 6);
		add(vbox_main);

        //toolbar ---------------------------------------------------
        
        //toolbar
		toolbar = new Gtk.Toolbar ();
		toolbar.toolbar_style = ToolbarStyle.BOTH_HORIZ;
		toolbar.get_style_context().add_class(Gtk.STYLE_CLASS_PRIMARY_TOOLBAR);
		toolbar.set_icon_size(IconSize.LARGE_TOOLBAR);
		//toolbar.set_size_request(-1,48);
		vbox_main.add(toolbar);

		//btn_prev
		btn_prev = new Gtk.ToolButton.from_stock ("gtk-go-back");
		btn_prev.is_important = false;
		btn_prev.label = _("Previous");
		btn_prev.set_tooltip_text (_("Previous Widget"));
        toolbar.add(btn_prev);

        btn_prev.clicked.connect(btn_prev_clicked);

		//btn_next
		btn_next = new Gtk.ToolButton.from_stock ("gtk-go-forward");
		btn_next.is_important = false;
		btn_next.label = _("Next");
		btn_next.set_tooltip_text (_("Next Widget"));
        toolbar.add(btn_next);

        btn_next.clicked.connect(btn_next_clicked);

		//btn_start
		btn_start = new Gtk.ToolButton.from_stock ("gtk-media-play");
		btn_start.is_important = false;
		btn_start.label = _("Start");
		btn_start.set_tooltip_text (_("Start/Restart Widget"));
        toolbar.add(btn_start);

        btn_start.clicked.connect(btn_start_clicked);

		//btn_stop
		btn_stop = new Gtk.ToolButton.from_stock ("gtk-media-stop");
		btn_stop.is_important = false;
		btn_stop.label = _("Start");
		btn_stop.set_tooltip_text (_("Stop Widget"));
        toolbar.add(btn_stop);

        btn_stop.clicked.connect(btn_stop_clicked);
        
        //separator1
		var separator1 = new Gtk.SeparatorToolItem();
		separator1.set_draw(true);
		toolbar.add(separator1);
		
		//btn_edit_gui
		btn_edit_gui = new Gtk.ToolButton.from_stock ("gtk-preferences");
		btn_edit_gui.is_important = false;
		btn_edit_gui.label = _("Edit");
		btn_edit_gui.set_tooltip_text (_("Edit Widget"));
        toolbar.add(btn_edit_gui);

        btn_edit_gui.clicked.connect(btn_edit_gui_clicked);
        
		//btn_edit
		btn_edit = new Gtk.ToolButton.from_stock ("gtk-edit");
		btn_edit.is_important = false;
		btn_edit.label = _("Manual Edit");
		btn_edit.set_tooltip_text (_("Edit file manually in a text editor"));
        toolbar.add(btn_edit);

        btn_edit.clicked.connect(btn_edit_clicked);
        
        //separator1
		var separator2 = new Gtk.SeparatorToolItem();
		separator2.set_draw(true);
		toolbar.add(separator2);

		//btn_scan
		btn_scan = new Gtk.ToolButton.from_stock ("gtk-refresh");
		btn_scan.is_important = false;
		btn_scan.label = _("Refresh");
		btn_scan.set_tooltip_text (_("Reload themes"));
        toolbar.add(btn_scan);

        btn_scan.clicked.connect(btn_scan_clicked);
        
		//btn_generate_preview
		btn_generate_preview = new Gtk.ToolButton.from_stock ("gtk-missing-image");
		btn_generate_preview.is_important = false;
		btn_generate_preview.label = _("Generate Preview");
		btn_generate_preview.set_tooltip_text (_("Generate preview image for this widget"));
        toolbar.add(btn_generate_preview);
		
		btn_generate_preview.set_icon_widget(new Gtk.Image.from_file(App.share_folder + "/conky-manager/images/image-generate24x24.png"));
		
        btn_generate_preview.clicked.connect(btn_generate_preview_clicked);

		//btn_generate_preview_all
		btn_generate_preview_all = new Gtk.ToolButton.from_stock ("gtk-missing-image");
		btn_generate_preview_all.is_important = false;
		btn_generate_preview_all.label = _("Generate Missing Previews");
		btn_generate_preview_all.set_tooltip_text (_("Generate missing preview images for all widgets"));
        toolbar.add(btn_generate_preview_all);
		
		btn_generate_preview_all.set_icon_widget(new Gtk.Image.from_file(App.share_folder + "/conky-manager/images/image-generate-all24x24.png"));
		
        btn_generate_preview_all.clicked.connect(btn_generate_preview_all_clicked);

		//btn_kill_all
		btn_kill_all = new Gtk.ToolButton.from_stock ("gtk-cancel");
		btn_kill_all.is_important = false;
		btn_kill_all.label = _("Stop All Widgets");
		btn_kill_all.set_tooltip_text (_("Stop all running widgets"));
        toolbar.add(btn_kill_all);

        btn_kill_all.clicked.connect(btn_kill_all_clicked);
        
        //separator
		var separator = new Gtk.SeparatorToolItem();
		separator.set_draw(false);
		separator.set_expand(true);
		toolbar.add(separator);
		
		//btn_settings
		btn_settings = new Gtk.ToolButton.from_stock ("gtk-preferences");
		btn_settings.is_important = false;
		btn_settings.label = _("Settings");
		btn_settings.set_tooltip_text (_("Application Settings"));
        toolbar.add(btn_settings);

        btn_settings.clicked.connect(btn_settings_clicked);

        //btn_donate
		btn_donate = new Gtk.ToolButton.from_stock ("gtk-dialog-info");
		btn_donate.is_important = false;
		btn_donate.label = _("Donate");
		btn_donate.set_tooltip_text (_("Donate"));
        toolbar.add(btn_donate);

        btn_donate.clicked.connect(() => { show_donation_window(false); });
        
        //btn_about
		btn_about = new Gtk.ToolButton.from_stock ("gtk-about");
		btn_about.is_important = false;
		btn_about.label = _("About");
		btn_about.set_tooltip_text (_("About"));
        toolbar.add(btn_about);

        btn_about.clicked.connect(btn_about_clicked);
        
        //hbox_widget
        hbox_widget = new Box (Orientation.HORIZONTAL, 6);
        hbox_widget.margin_left = 3;
        hbox_widget.margin_right = 3;
		vbox_main.add(hbox_widget);

		//lbl_widget_name
		lbl_widget_name = new Label ("");
		lbl_widget_name.use_markup = true;
		lbl_widget_name.halign = Align.START;
		lbl_widget_name.max_width_chars = 100;
		lbl_widget_name.ellipsize = Pango.EllipsizeMode.END;
		hbox_widget.pack_start (lbl_widget_name, true, true, 0);
		
		//cmb_type
		cmb_type = new ComboBox();
		hbox_widget.pack_start (cmb_type, false, true, 0);

		CellRendererText cell_type = new CellRendererText();
        cmb_type.pack_start(cell_type, false );
        cmb_type.set_cell_data_func (cell_type, (cell_type, cell, model, iter) => {
			string type;
			model.get (iter, 0, out type,-1);
			(cell as Gtk.CellRendererText).text = type;
		});

		//vbox_status
        vbox_status = new Box (Orientation.VERTICAL, 3);
        vbox_status.no_show_all = true;
        vbox_status.margin = 3;
		vbox_main.add(vbox_status);

		//lbl_status
		lbl_status = new Label ("");
		lbl_status.halign = Align.START;
		lbl_status.max_width_chars = 100;
		lbl_status.ellipsize = Pango.EllipsizeMode.END;
		vbox_status.pack_start (lbl_status, false, true, 0);
		
		//hbox_progressbar
        hbox_progressbar = new Box (Orientation.HORIZONTAL, 6);
		vbox_status.add(hbox_progressbar);
		
		//progressbar
		progressbar = new ProgressBar();
		progressbar.no_show_all = true;
		progressbar.set_size_request(-1,20);
		//progressbar.pulse_step = 0.2;
		hbox_progressbar.pack_start (progressbar, true, true, 0);
		
		//btn_cancel_action
		btn_cancel_action = new Gtk.Button.with_label (" " + _("Stop") + " ");
		btn_cancel_action.set_size_request(50,-1);
		btn_cancel_action.set_tooltip_text(_("Stop"));
		hbox_progressbar.pack_start (btn_cancel_action, false, false, 0);
		
		//sw_preview
		sw_preview = new ScrolledWindow(null, null);
		sw_preview.set_shadow_type(ShadowType.ETCHED_IN);
		sw_preview.expand = true;
		vbox_main.add(sw_preview);

		//img_preview
		img_preview = new Image();
		ebox_preview = new EventBox();
		ebox_preview.add(img_preview);
		sw_preview.add(ebox_preview);
		
		//tooltip
		string tt = _("Use the Arrow Keys to Browse.\nPress ENTER to Start and Stop.");
		sw_preview.set_tooltip_text(tt);
		
		//initialize
		cmb_type_refresh();
		
		//show first widget
		show_preview(selected_widget());
		
		this.key_press_event.connect ((w, event) => {

			if (!toolbar.sensitive) { return false; }
			
			if (event.keyval == 65361) {
				btn_prev_clicked();
				return true;
			}
			else if (event.keyval == 65363) {
				btn_next_clicked();
				return true;
			}
			else if (event.keyval == 65293) {
				if (selected_widget().enabled){
					btn_stop_clicked();
				}
				else{
					btn_start_clicked();
				}
				return true;
			}

			return false;
		});

		timer_init = Timeout.add(100, initialize_themes);
		
	}
	
	private bool initialize_themes(){
		Source.remove(timer_init);
		if (App.conkyrc_list.size == 0){
			btn_scan_clicked();
		}
		return true;
	}
	
	//actions

	private void cmb_type_refresh(){
		ListStore store = new ListStore(1, typeof(string));

		TreeIter iter;
		store.append(out iter);
		store.set (iter, 0, "Widget");
		store.append(out iter);
		store.set (iter, 0, "Theme");
			
		cmb_type.set_model (store);
		cmb_type.active = 0;
	}

	private void btn_prev_clicked(){
		if (App.selected_widget_index > 0){
			App.selected_widget_index--;
		}
		show_preview(selected_widget());
	}

	private void btn_next_clicked(){
		if (App.selected_widget_index < (App.conkyrc_list.size - 1)){
			App.selected_widget_index++;
		}
		show_preview(selected_widget());
	}
	
	private void btn_start_clicked(){
		ConkyRC rc = selected_widget();
		rc.start_conky();
		show_preview(rc);
	}
	
	private void btn_stop_clicked(){
		ConkyRC rc = selected_widget();
		rc.stop_conky();
		show_preview(rc);
	}
	
	private void btn_edit_gui_clicked(){
		ConkyRC rc = selected_widget();
		
		var dialog = new EditWindow(rc);
		dialog.set_transient_for(this);
		dialog.show_all();
		dialog.run();
		dialog.destroy();
	}

	private void btn_edit_clicked(){
		ConkyRC rc = selected_widget();
		
		exo_open_textfile(rc.path);
	}

	private void btn_scan_clicked(){
		scan_themes();
	}

	private void btn_generate_preview_clicked(){
		ConkyRC rc = selected_widget();
		
		toolbar.sensitive = false;
		hbox_widget.sensitive = false;
		gtk_set_busy(true, this);
		
		rc.generate_preview();
		
		toolbar.sensitive = true;
		hbox_widget.sensitive = true;
		gtk_set_busy(false, this);
		
		show_preview(rc);
	}

	private void btn_generate_preview_all_clicked(){

		progress_begin("Generating previews...");
		sw_preview.visible = true;
		is_aborted = false;
		img_preview.pixbuf = null;
		
		btn_cancel_action.clicked.connect(btn_cancel_action_generate_preview_all);
		
		try {
			is_running = true;
			Thread.create<void> (btn_generate_preview_all_clicked_thread, true);
		} catch (ThreadError e) {
			is_running = false;
			log_error (e.message);
		}

		while(is_running){
			Thread.usleep ((ulong) 200000);
			gtk_do_events();
		}
				
		btn_cancel_action.clicked.disconnect(btn_cancel_action_generate_preview_all);
		
		progress_hide();
	}
	
	private void btn_generate_preview_all_clicked_thread(){
		//get total count
		int count_total = 0;
		foreach(ConkyRC rc in App.conkyrc_list){
			if (!file_exists(rc.image_path)){
				count_total++;
			}
		}
		
		int count = 0;
		foreach(ConkyRC rc in App.conkyrc_list){
			
			if (is_aborted) { break; }
			
			if (!file_exists(rc.image_path)){
				current_rc = rc;
				rc.generate_preview();
				current_rc = null;
				
				count++;
				progressbar.fraction = count / (count_total * 1.0);

				show_preview(rc);
				
				lbl_status.label = _("Generating Previews") + " [%d OF %d]\n%s".printf(count, count_total, rc.name);
				gtk_do_events();
			}
		}
		
		is_running = false;
	}
	
	private void btn_kill_all_clicked(){
		App.kill_all_conky();
	}
	
	private void btn_settings_clicked(){
		var dialog = new SettingsWindow();
		dialog.set_transient_for(this);
		dialog.show_all();
		dialog.run();
		dialog.destroy();
	}

	public void show_donation_window(bool on_exit){
		var dialog = new DonationWindow(on_exit);
		dialog.set_transient_for(this);
		dialog.show_all();
		dialog.run();
		dialog.destroy();
	}

	private void btn_about_clicked (){
		
		var dialog = new Gtk.AboutDialog();
		dialog.set_destroy_with_parent (true);
		dialog.set_transient_for (this);
		dialog.set_modal (true);
		
		//dialog.artists = {"", ""};
		dialog.authors = {"Tony George"};
		dialog.documenters = null; 
		//dialog.translator_credits = "tomberry88 (Italian)"; 
		//dialog.add_credit_section("Sponsors", {"Colin Mills"});
		
		dialog.program_name = "Conky Manager";
		dialog.comments = _("Utility for managing Conky configuration files");
		dialog.copyright = "Copyright © 2014 Tony George (teejee2008@gmail.com)";
		dialog.version = AppVersion;
		
		try{
			dialog.logo = new Gdk.Pixbuf.from_file (App.share_folder + """/pixmaps/conky-manager.png""");
		}
        catch(Error e){
	        log_error (e.message);
	    }

		dialog.license = "This program is free for personal and commercial use and comes with absolutely no warranty. You use this program entirely at your own risk. The author will not be liable for any damages arising from the use of this program.";
		dialog.wrap_license = true;

		dialog.website = "http://teejeetech.in";
		dialog.website_label = "http://teejeetech.blogspot.in";

		dialog.response.connect ((response_id) => {
			if (response_id == Gtk.ResponseType.CANCEL || response_id == Gtk.ResponseType.DELETE_EVENT) {
				dialog.hide_on_delete ();
			}
		});

		dialog.present ();
	}
	
	private void show_preview(ConkyRC? rc){
		sw_preview.visible = true;
		img_preview.visible = true;
		img_preview.pixbuf = null;
		
		if (rc == null){
			img_preview.pixbuf = null;
			return;
		}
		
		lbl_widget_name.label = ((rc.enabled) ? "<span font-weight='bold'>[Running] </span>" : "") + " %d OF %d | ".printf(App.selected_widget_index + 1, App.conkyrc_list.size) + escape_html(rc.name);
		
		int screen_width = Gdk.Screen.width();
		int screen_height = Gdk.Screen.height();

		if ((rc.image_path.length > 0) && file_exists(rc.image_path)){
			try{
				Gdk.Pixbuf px = new Gdk.Pixbuf.from_file(rc.image_path);

				//scale down the image if it is very large
				if ((px.width > (screen_width * 1.5)) || (px.height > (screen_height * 1.5))){
					//scale down 50%
					int scaled_width = px.width / 2;
					int scaled_height = px.height / 2;
					px = new Gdk.Pixbuf.from_file_at_scale(rc.image_path,scaled_width,scaled_height,true);
					img_preview.pixbuf = px;
				}
				else{
					img_preview.pixbuf = px;
				}
			}
			catch(Error e){
				log_error (e.message);
			}
		}
		else{
			img_preview.pixbuf = null;
		}
	}

	private void scan_themes(){
		progress_begin(_("Searching directories..."));
		resize(def_width,30);
		
		btn_cancel_action.clicked.connect(btn_cancel_action_scan);
		
		try {
			is_running = true;
			Thread.create<void> (scan_themes_thread, true);
		} catch (ThreadError e) {
			is_running = false;
			log_error (e.message);
		}

		while(is_running){
			Thread.usleep ((ulong) 200000);
			progressbar.pulse();
			gtk_do_events();
		}
		
		btn_cancel_action.clicked.disconnect(btn_cancel_action_scan);
		
		progress_hide();
		resize(def_width,def_height);

		if (App.selected_widget_index < App.conkyrc_list.size){
			show_preview(selected_widget());
		}
	}
	
	private void scan_themes_thread(){
		App.load_themes_and_widgets();
		is_running = false;
	}

	private void btn_cancel_action_scan(){
		App.load_themes_and_widgets_cancel();
	}
	
	private void btn_cancel_action_generate_preview_all(){
		is_aborted = true;
		if (current_rc != null){
			current_rc.stop_conky();
		}
	}
	
	private void progress_begin(string message = ""){
		toolbar.sensitive = false;
		hbox_widget.visible = false;

		vbox_status.visible = true;
		lbl_status.visible = true;
		hbox_progressbar.visible = true;
		progressbar.visible = true;
		btn_cancel_action.visible = true;
		sw_preview.visible = false;
		
		progressbar.fraction = 0.0;
		lbl_status.label = message;

		//gtk_set_busy(true, this);
		gtk_do_events();
	}
	
	private void progress_hide(string message = ""){
		toolbar.sensitive = true;		
		hbox_widget.visible = true;		

		vbox_status.visible = false;
		lbl_status.visible = false;
		hbox_progressbar.visible = false;
		progressbar.visible = false;
		btn_cancel_action.visible = false;
		sw_preview.visible = true;

		progressbar.fraction = 0.0;
		lbl_status.label = message;

		//gtk_set_busy(false, this);
		gtk_do_events();
	}
	
	private ConkyRC? selected_widget(){
		if (App.selected_widget_index >= App.conkyrc_list.size){
			App.selected_widget_index = 0;
		}
		
		if (App.selected_widget_index < App.conkyrc_list.size){
			return App.conkyrc_list[App.selected_widget_index];
		}
		else{
			return null;
		}
		
	}
}
