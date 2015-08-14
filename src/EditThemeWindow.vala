/*
 * EditThemeWindow.vala
 * 
 * Copyright 2015 Tony George <teejee2008@gmail.com>
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
using TeeJee.JSON;
using TeeJee.ProcessManagement;
using TeeJee.GtkHelper;
using TeeJee.System;
using TeeJee.Misc;

public class EditThemeWindow : Dialog {
	private Box vbox_main;
	private Box hbox_action;
	private Button btn_ok;
	private Button btn_cancel;
	private TreeView tv_widget;
	private ScrolledWindow sw_widget;
	private Entry entry_name;
	private ComboBox cmb_wallpaper;
	private ComboBox cmb_scaling;
    private FileChooserButton fcb_wallpaper;
	public ConkyTheme th = null;

	public EditThemeWindow(ConkyTheme? _theme) {
		
        window_position = WindowPosition.CENTER_ON_PARENT;
		set_destroy_with_parent (true);
		set_modal (true);
        skip_taskbar_hint = false;
        set_default_size (450, 400);	
		icon = get_app_icon(16);
		
		th = _theme;
		title = (th == null) ? _("Save Theme") : _("Edit Theme");

	    vbox_main = get_content_area();
		vbox_main.margin = 6;
		vbox_main.spacing = 6;

		//theme_name
        Box hbox_theme_name = new Box (Orientation.HORIZONTAL, 6);
		vbox_main.add(hbox_theme_name);
		
		Label lbl_theme_name = new Gtk.Label(_("Theme Name"));
		lbl_theme_name.xalign = (float) 0.0;
		hbox_theme_name.add(lbl_theme_name);
		
		entry_name = new Gtk.Entry();
		entry_name.xalign = (float) 0.0;
		entry_name.hexpand = true;
		entry_name.text = (th == null)? "" : th.base_name.replace(".cmtheme","");
		hbox_theme_name.add(entry_name);
		
		init_list_view();

        // lbl_header_wp
		Label lbl_header_wp = new Label ("<b>" + _("Wallpaper") + " - </b><i>" + _("Include desktop wallpaper in theme") + "</i>");
		lbl_header_wp.margin_top = 5;
		lbl_header_wp.set_use_markup(true);
		lbl_header_wp.halign = Align.START;
		vbox_main.pack_start (lbl_header_wp, false, true, 0);
		
		//grid_wp
		Grid grid_wp = new Grid();
        grid_wp.set_column_spacing (6);
        grid_wp.set_row_spacing (6);
        vbox_main.pack_start (grid_wp, false, true, 0);

		//lbl_wp_option
		Label lbl_wp_option = new Label (_("Wallpaper") + ":" );
		lbl_wp_option.xalign = (float) 0.0;
		grid_wp.attach(lbl_wp_option,0,0,1,1);

		//cmb_wallpaper
		cmb_wallpaper = new ComboBox();
		cmb_wallpaper.hexpand = true;
		grid_wp.attach(cmb_wallpaper,1,0,1,1);

		CellRendererText cell_wallpaper = new CellRendererText();
        cmb_wallpaper.pack_start(cell_wallpaper, false );
        cmb_wallpaper.set_cell_data_func (cell_wallpaper, (cell_wallpaper, cell, model, iter) => {
			string type;
			model.get (iter, 0, out type,-1);
			(cell as Gtk.CellRendererText).text = type;
		});
		
		var store = new Gtk.ListStore(1, typeof(string));
		TreeIter iter;
		store.append(out iter);
		store.set (iter, 0, _("None"));
		store.append(out iter);
		store.set (iter, 0, _("Custom Wallpaper"));
		switch (App.desktop){
			case "cinnamon":	
			case "gnome":
			case "unity":	
			case "xfce":	
			case "lxde":	
				store.append(out iter);
				store.set (iter, 0, _("Current Wallpaper"));
				break;
		}
		cmb_wallpaper.set_model (store);
		cmb_wallpaper.active = 0;

		//lbl_custom_wallpaper
		Label lbl_custom_wallpaper = new Label (_("Choose File") + ":");
		lbl_custom_wallpaper.xalign = (float) 0.0;
		grid_wp.attach(lbl_custom_wallpaper,0,1,1,1);

		//fcb_wallpaper
		fcb_wallpaper = new FileChooserButton (_("Select Wallpaper"), FileChooserAction.OPEN);
		grid_wp.attach(fcb_wallpaper,1,1,1,1);
		
		fcb_wallpaper.selection_changed.connect(()=>{
			if (th != null){
				th.wallpaper_path = fcb_wallpaper.get_file().get_path();
			}
		});

		if (th != null){
			if (th.wallpaper_path.length > 0){
				cmb_wallpaper.active = 1;
				fcb_wallpaper.select_filename(th.wallpaper_path);
			}
		}

		//lbl_scaling
		Label lbl_scaling = new Label (_("Scaling") + ":");
		lbl_scaling.xalign = (float) 0.0;
		grid_wp.attach(lbl_scaling,0,2,1,1);

		//cmb_scaling
		cmb_scaling = new ComboBox();
		cmb_scaling.hexpand = true;
		grid_wp.attach(cmb_scaling,1,2,1,1);

		CellRendererText cell_scaling= new CellRendererText();
        cmb_scaling.pack_start(cell_scaling, false );
        cmb_scaling.set_cell_data_func (cell_scaling, (cell_scaling, cell, model, iter) => {
			string type;
			model.get (iter, 0, out type,-1);
			(cell as Gtk.CellRendererText).text = type;
		});
		
		store = new Gtk.ListStore(1, typeof(string));
		foreach(string option in App.bg_scaling){
			store.append(out iter);
			store.set (iter, 0, option);
		}
		cmb_scaling.set_model (store);
		
		if (th == null){
			cmb_scaling.active = 0;
		}
		else{
			int index = -1;
			foreach(string option in App.bg_scaling){
				index++;
				if (option == th.wallpaper_scaling){
					cmb_scaling.active = index;
					break;
				}
			}
		}

		//set initial state
		cmb_wallpaper.changed.connect(()=>{
			fcb_wallpaper.sensitive = (cmb_wallpaper.active == 1);
			cmb_scaling.sensitive = (cmb_wallpaper.active != 0);
		});
		fcb_wallpaper.sensitive = (cmb_wallpaper.active == 1);
		cmb_scaling.sensitive = (cmb_wallpaper.active != 0);
		
		tv_widget_refresh();
		
		//hbox_commands --------------------------------------------------
		
		hbox_action = (Box) get_action_area();
		
		//btn_ok
		btn_ok = new Button.with_label("  " + _("OK"));
		btn_ok.set_image(new Image.from_stock ("gtk-ok", IconSize.MENU));
		hbox_action.add(btn_ok);	
			
        btn_ok.clicked.connect(btn_ok_clicked);

		//btn_cancel
		btn_cancel = new Button.with_label("  " + _("Cancel"));
		btn_cancel.set_image (new Image.from_stock ("gtk-cancel", IconSize.MENU));
		hbox_action.add(btn_cancel);
		
		btn_cancel.clicked.connect(()=>{ this.response(Gtk.ResponseType.CANCEL); });
	}
	
	private void init_list_view(){
		
        // lbl_header_widgets
		Label lbl_header_widgets = new Label ("<b>" + _("Widgets") + " - </b><i>" + _("Include running widgets in theme") + "</i>");
		lbl_header_widgets.set_tooltip_text(_("Include running widgets in theme"));
		lbl_header_widgets.margin_top = 5;
		lbl_header_widgets.set_use_markup(true);
		lbl_header_widgets.halign = Align.START;
		vbox_main.pack_start (lbl_header_widgets, false, true, 0);
		
		//list view
		tv_widget = new TreeView();
		tv_widget.get_selection().mode = SelectionMode.SINGLE;
		tv_widget.headers_visible = false;
		tv_widget.set_rules_hint (true);
		
		sw_widget = new ScrolledWindow(null, null);
		sw_widget.set_shadow_type (ShadowType.ETCHED_IN);
		sw_widget.add (tv_widget);
		sw_widget.expand = true;
		vbox_main.add(sw_widget);

		TreeViewColumn col_widget = new TreeViewColumn();
		col_widget.title = "";
		tv_widget.append_column(col_widget);
		
		CellRendererToggle cell_widget_enable = new CellRendererToggle ();
		cell_widget_enable.activatable = true;
		col_widget.pack_start (cell_widget_enable, false);
		
		col_widget.set_cell_data_func (cell_widget_enable, (cell_layout, cell, model, iter)=>{
			bool val;
			model.get (iter, 0, out val, -1);
			(cell as Gtk.CellRendererToggle).active = val;
		});
		
		cell_widget_enable.toggled.connect(cell_widget_enable_toggled);
		
		CellRendererText cell_widget_name = new CellRendererText ();
		col_widget.pack_start (cell_widget_name, false);
		
		col_widget.set_cell_data_func (cell_widget_name, (cell_layout, cell, model, iter)=>{
			ConkyRC rc;
			model.get (iter, 1, out rc, -1);
			(cell as Gtk.CellRendererText).text = rc.name;
		});
	}

	private void cell_widget_enable_toggled (string path){
		TreeIter iter;
		var model = (Gtk.ListStore)tv_widget.model;
		bool enabled;

		model.get_iter_from_string (out iter, path);
		model.get (iter, 0, out enabled, -1);
		enabled = !enabled;
		model.set (iter, 0, enabled);
	}
	
	private void tv_widget_refresh(){
		var model = new Gtk.ListStore(2, typeof(bool), typeof(ConkyRC));
		
		var list = new Gee.ArrayList<string>();
		
		if (th != null){
			//add existing - selected
			foreach(ConkyRC rc in th.conkyrc_list){
				if (!list.contains(rc.path)){ 
					TreeIter iter;
					model.append(out iter);
					model.set(iter, 0, true);
					model.set(iter, 1, rc);
					list.add(rc.path); 
				}
			}
			//add running - unselected
			foreach(ConkyRC rc in App.conkyrc_list){
				if (rc.enabled) { 
					if (!list.contains(rc.path)){ 
						TreeIter iter;
						model.append(out iter);
						model.set(iter, 0, false);
						model.set(iter, 1, rc);
						list.add(rc.path); 
					}
				}
			}
		}
		else{
			//add running - selected
			foreach(ConkyRC rc in App.conkyrc_list){
				if (rc.enabled) { 
					if (!list.contains(rc.path)){ 
						TreeIter iter;
						model.append(out iter);
						model.set(iter, 0, true);
						model.set(iter, 1, rc);
						list.add(rc.path); 
					}
				}
			}
		}
		
		tv_widget.set_model(model);
		tv_widget.columns_autosize();
	}
	
	private void btn_ok_clicked(){
		if (entry_name.get_text().length == 0){
			string title = _("Name Required");
			string msg = _("Please enter theme name");
			gtk_messagebox(title,msg,this,true);
			return;
		}
		
		int size = 0;
		tv_widget.model.foreach((model, path, iter) => {
			size++;
			return false;
		});

		if (size == 0){
			string title = _("No Widgets Selected");
			string msg = _("Select the widgets to include in theme");
			gtk_messagebox(title,msg,this,true);
			return;
		}

		if (th == null){
			string name = entry_name.text.replace(".cmtheme","");
			string theme_dir = App.data_dir + "/" + name;
			string theme_file_path = theme_dir + "/" + name + ".cmtheme";
			if (!dir_exists(theme_dir)){ create_dir(theme_dir); };
			th = new ConkyTheme.empty(theme_file_path);
			App.conkytheme_list.add(th);
		}
		
		th.conkyrc_list.clear();
		
		string txt = "";
		
		var model = (Gtk.ListStore)tv_widget.model;
		TreeIter iter;
		bool enabled;
		ConkyRC rc;
		bool iterExists = model.get_iter_first (out iter);
		while (iterExists){
			model.get (iter, 0, out enabled, 1, out rc, -1);
			if (enabled){
				txt += rc.name + "\n";
				th.conkyrc_list.add(rc);
			}
			iterExists = model.iter_next (ref iter);
		}
		
		//TODO: cleanup the following code
		if (cmb_wallpaper.active == 0){
			th.wallpaper_path = "";
			th.wallpaper_scaling = "";
		}
		else if (cmb_wallpaper.active == 2){
			th.wallpaper_path = th.save_current_wallpaper();
			th.wallpaper_scaling = gtk_combobox_get_value(cmb_scaling,0,"");
			
			txt += th.wallpaper_path.replace(Environment.get_home_dir(),"~") + "\n";
			txt += "wallpaper-scaling:" + th.wallpaper_scaling + "\n";
		}
		else if ((cmb_wallpaper.active == 1)&&(file_exists(fcb_wallpaper.get_filename()))){
			if (fcb_wallpaper.get_filename() != th.wallpaper_path){
				th.wallpaper_path = th.save_wallpaper(fcb_wallpaper.get_filename());
			}
			th.wallpaper_scaling = gtk_combobox_get_value(cmb_scaling,0,"");
			
			txt += th.wallpaper_path.replace(Environment.get_home_dir(),"~") + "\n";
			txt += "wallpaper-scaling:" + th.wallpaper_scaling + "\n";
		}

		write_file(th.path,txt);

		this.response(Gtk.ResponseType.OK); 
	}
}
