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

public class MainWindow : Window 
{
	private Notebook tabMain;

	private Label lblThemeTab;
	private Box vboxTheme;
	private Box hboxThemeButtons;

	private Label lblOptionsTab;
	private Box vboxOptions;

	private Label lblEditTab;
	private Box vboxEdit;
	private Box hboxEdit;

	private Label lblHeaderStartup;
	private CheckButton chkStartup;
	
	private TreeView tvTheme;
	private ScrolledWindow swTheme;
	
	private TreeView tvConfig;
	private ScrolledWindow swConfig;

	private Button btnThemeInfo;
	private Button btnThemePreview;
	
	//private ComboBox comboTheme;

	public MainWindow() {
		this.title = AppName + " v" + AppVersion + " by " + AppAuthor + " (" + "teejeetech.blogspot.in" + ")";
        this.window_position = WindowPosition.CENTER;
        this.destroy.connect (Gtk.main_quit);
        set_default_size (600, 20);	

		// tabMain
        tabMain = new Notebook ();
		tabMain.margin = 6;
		add(tabMain);
		
		// vboxTheme
        vboxTheme = new Box (Orientation.VERTICAL, 6);
		vboxTheme.margin = 6;

        // lblThemeTab
		lblThemeTab = new Label (_("Theme"));

		tabMain.append_page (vboxTheme, lblThemeTab);
		
        // hboxTheme
        //hboxTheme = new Box (Orientation.HORIZONTAL, 6);
        //vboxTheme.add(hboxTheme);

		//tvTheme
		tvTheme = new TreeView();
		tvTheme.get_selection().mode = SelectionMode.SINGLE;
		tvTheme.get_selection().changed.connect(tvTheme_selection_changed);
		tvTheme.set_tooltip_text ("");
		tvTheme.set_rules_hint (true);
		//tvTheme.headers_visible = false;
		
		swTheme = new ScrolledWindow(tvTheme.get_hadjustment (), tvTheme.get_vadjustment ());
		swTheme.set_shadow_type (ShadowType.ETCHED_IN);
		swTheme.add (tvTheme);
		swTheme.set_size_request (-1, 250);
		vboxTheme.pack_start (swTheme, true, true, 0);
		
		// Theme Name Column
		TreeViewColumn colName = new TreeViewColumn();
		colName.title = _("Theme");
		colName.resizable = true;
		colName.expand = true;
		
		CellRendererText cellName = new CellRendererText ();
		cellName.ellipsize = Pango.EllipsizeMode.END;
		cellName.width = 200;
		colName.pack_start (cellName, false);
		colName.set_cell_data_func (cellName, tvTheme_cellName_render);
		tvTheme.append_column(colName);
		
		// 'Enabled' Column
		TreeViewColumn colEnabled = new TreeViewColumn();
		colEnabled.title = _("Enable");
		colEnabled.resizable = false;
		//colEnabled.sizing = TreeViewColumnSizing.AUTOSIZE; 
		colEnabled.expand = false;
		
		CellRendererToggle cellEnabled = new CellRendererToggle ();
		cellEnabled.radio = false;
		cellEnabled.activatable = true;
		cellEnabled.width = 50;
		cellEnabled.toggled.connect (tvTheme_cellEnabled_toggled);
		colEnabled.pack_start (cellEnabled, false);
		colEnabled.set_cell_data_func (cellEnabled, tvTheme_cellEnabled_render);
		tvTheme.append_column(colEnabled);
		
		//tvConfig
		tvConfig = new TreeView();
		tvConfig.get_selection().mode = SelectionMode.MULTIPLE;
		tvConfig.set_tooltip_text ("");
		tvConfig.set_rules_hint (true);
		//tvConfig.headers_visible = false;
		
		swConfig = new ScrolledWindow(tvConfig.get_hadjustment (), tvConfig.get_vadjustment ());
		swConfig.set_shadow_type (ShadowType.ETCHED_IN);
		swConfig.add (tvConfig);
		swConfig.set_size_request (-1, 180);
		vboxTheme.pack_start (swConfig, false, true, 0);
		
		// Theme Name Column
		colName = new TreeViewColumn();
		colName.title = _("Config");
		colName.resizable = true;
		colName.expand = true;
		
		cellName = new CellRendererText ();
		cellName.ellipsize = Pango.EllipsizeMode.END;
		cellName.width = 200;
		colName.pack_start (cellName, false);
		colName.set_cell_data_func (cellName, tvConfig_cellName_render);
		tvConfig.append_column(colName);
		
		// 'Enabled' Column
		colEnabled = new TreeViewColumn();
		colEnabled.title = _("Enable");
		colEnabled.resizable = false;
		colEnabled.expand = false;
		
		cellEnabled = new CellRendererToggle ();
		cellEnabled.radio = false;
		cellEnabled.activatable = true;
		cellEnabled.width = 50;
		cellEnabled.toggled.connect (tvConfig_cellEnabled_toggled);
		colEnabled.pack_start (cellEnabled, false);
		colEnabled.set_cell_data_func (cellEnabled, tvConfig_cellEnabled_render);
		tvConfig.append_column(colEnabled);
		
		//hboxThemeButtons
		hboxThemeButtons = new Box (Orientation.HORIZONTAL, 6); 
		hboxThemeButtons.set_homogeneous(true);
		vboxTheme.add(hboxThemeButtons);
		
		//btnThemeInfo
		btnThemeInfo = new Button.with_label(_("Info"));
		btnThemeInfo.set_image (new Image.from_stock (Stock.INFO, IconSize.MENU));
        btnThemeInfo.clicked.connect (btnThemeInfo_clicked);
        btnThemeInfo.set_tooltip_text (_("Theme Info"));
        btnThemeInfo.set_sensitive(false);
		hboxThemeButtons.add(btnThemeInfo);
		
		//btnThemePreview
		btnThemePreview = new Button.with_label(_("Preview"));
		//btnThemePreview.set_image (new Image.from_stock (Stock.INFO, IconSize.MENU));
        btnThemePreview.clicked.connect (btnThemePreview_clicked);
        btnThemePreview.set_tooltip_text (_("Preview Theme"));
        btnThemePreview.set_sensitive(false);
		hboxThemeButtons.add(btnThemePreview);
		
		// Options tab ---------------------------
		
		// vboxOptions
        vboxOptions = new Box (Orientation.VERTICAL, 6);
		vboxOptions.margin = 12;

        // lblOptionsTab
		lblOptionsTab = new Label (_("Options"));

		tabMain.append_page (vboxOptions, lblOptionsTab);
		
        // hboxOptions
        //hboxOptions = new Box (Orientation.HORIZONTAL, 6);
        //vboxOptions.add(hboxOptions);
        
        // lblHeaderStartup
		lblHeaderStartup = new Gtk.Label("<b>" + _("Startup") + "</b>");
		lblHeaderStartup.set_use_markup(true);
		lblHeaderStartup.xalign = (float) 0.0;
		//lblHeaderStartup.margin_top = 6;
		lblHeaderStartup.margin_bottom = 6;
		vboxOptions.add(lblHeaderStartup);
		
		// chkStartup
		chkStartup = new CheckButton.with_label (_("Run Conky at system startup"));
		chkStartup.active = App.check_startup();
		chkStartup.clicked.connect (chkStartup_clicked);
		vboxOptions.add(chkStartup);
		
		
        // Edit tab ---------------------------
		
		// vboxEdit
        vboxEdit = new Box (Orientation.VERTICAL, 6);
		vboxEdit.margin = 6;

        // lblEditTab
		lblEditTab = new Label (_("Edit"));

		tabMain.append_page (vboxEdit, lblEditTab);
		
        // hboxEdit
        hboxEdit = new Box (Orientation.HORIZONTAL, 6);
        vboxEdit.add(hboxEdit);

        /*// comboTheme
        comboTheme = new ComboBox ();
        comboTheme.set_size_request (400,-1);
        comboTheme.changed.connect(comboTheme_changed);
        //hboxTheme.pack_start (comboTheme, true, true, 0);

		CellRendererText cell = new CellRendererText();
        comboTheme.pack_start( cell, false );
        comboTheme.set_attributes( cell, "text", 0 );
        comboTheme.set_tooltip_text (_("Theme"));
        */
        
		reload_themes();
		Utility.execute_command_async(new string[]{"sleep","10"});
	}

	public void reload_themes() {
		App.reload_themes();

		ListStore model = new ListStore(1,typeof(ConkyTheme));
		TreeIter iter;
		foreach(ConkyTheme theme in App.ThemeList) {
			model.append(out iter);
			model.set(iter, 0, theme);
		}
		tvTheme.model = model;
	}
	
	// tvTheme Handlers -----------
	
	private void tvTheme_cellEnabled_render (CellLayout cell_layout, CellRenderer cell, TreeModel model, TreeIter iter)
	{
		ConkyTheme theme;
		model.get (iter, 0, out theme, -1);
		(cell as Gtk.CellRendererToggle).active = theme.Enabled;
	}
	
	private void tvTheme_cellName_render (CellLayout cell_layout, CellRenderer cell, TreeModel model, TreeIter iter)
	{
		ConkyTheme theme;
		model.get (iter, 0, out theme, -1);
		(cell as Gtk.CellRendererText).text = theme.Name;
	}
	
	private void tvTheme_cellEnabled_toggled (string path)
	{
		set_busy(true, this);
		
		ConkyTheme theme;
		TreeIter iter;
		
		ListStore model = (ListStore) tvTheme.model; //get model
		model.get_iter_from_string (out iter, path); //get selected iter
		model.get (iter, 0, out theme, -1); //get theme
		
		theme.Enabled = !theme.Enabled;

		//refresh tvConfig 
		//Thread.usleep((ulong)1000000);
		model = (ListStore) tvConfig.model;
		tvConfig.model = null;
		tvConfig.model = model;
		
		set_busy(false, this);
	}

	private void tvTheme_selection_changed () 
	{
		set_busy(true, this);
		
		// populate config list ----------
		
		ConkyTheme theme = null;
		TreeIter iter;
		TreeModel model;
		ListStore store;
		
		if (tvTheme.get_selection().get_selected(out model, out iter)){
			model.get (iter, 0, out theme, -1); //get theme
			
			store = new ListStore(1,typeof(ConkyConfig));
			foreach(ConkyConfig conf in theme.ConfigList){
				store.append(out iter);
				store.set(iter, 0, conf);
				//debug("add: %s\n".printf(conf.Path));
			}
			tvConfig.model = store;
		}
		
		// set preview and info buttons ---------
		
		if (theme != null) {
			if (Utility.file_exists(theme.InfoFile)){
				btnThemeInfo.set_sensitive(true);
			}
			else{
				btnThemeInfo.set_sensitive(false);
			}
			
			if (Utility.file_exists(theme.PreviewImage)){
				btnThemePreview.set_sensitive(true);
			}
			else{
				btnThemePreview.set_sensitive(false);
			}
		}
		
		set_busy(false, this);
	}
	
	// tvConfig Handlers -----------
	
	private void tvConfig_cellEnabled_render (CellLayout cell_layout, CellRenderer cell, TreeModel model, TreeIter iter)
	{
		ConkyConfig conf;
		model.get (iter, 0, out conf, -1);
		(cell as Gtk.CellRendererToggle).active = conf.Enabled;
	}
	
	private void tvConfig_cellName_render (CellLayout cell_layout, CellRenderer cell, TreeModel model, TreeIter iter)
	{
		ConkyConfig conf;
		model.get (iter, 0, out conf, -1);
		(cell as Gtk.CellRendererText).text = conf.Name;
	}
	
	private void tvConfig_cellEnabled_toggled (string path)
	{
		set_busy(true, this);
		
		ConkyConfig conf;
		TreeIter iter;
		
		ListStore model = (ListStore) tvConfig.model; //get model
		model.get_iter_from_string (out iter, path); //get selected iter
		model.get (iter, 0, out conf, -1); //get theme
		
		if (conf.Enabled){
			conf.stop_conky();
		}
		else{
			conf.start_conky();
		} 
		
		set_busy(false, this);
	}
	
	private void set_busy (bool busy, Gtk.Window win) 
	{
		Gdk.Cursor? cursor = null;

		if (busy){
			cursor = new Gdk.Cursor(Gdk.CursorType.WATCH);
		}
		else{
			cursor = new Gdk.Cursor(Gdk.CursorType.ARROW);
		}
		
		var window = win.get_window ();
		
		if (window != null) {
			window.set_cursor (cursor);
		}
		
		do_events ();
	}
	
	private void do_events ()
    {
		while(Gtk.events_pending ())
			Gtk.main_iteration ();
	}
	
	private ConkyTheme? tvTheme_get_selected_theme(){
		ConkyTheme theme = null;
		TreeIter iter;
		TreeModel model;

		if (tvTheme.get_selection().get_selected(out model, out iter)){
			model.get (iter, 0, out theme, -1); //get theme
			return theme;
		}
		
		return null;
	}
	
	// hboxThemeButtons ------------------------
	
	private void btnThemeInfo_clicked () {
		ConkyTheme theme = tvTheme_get_selected_theme();
		if (theme != null){
			string info = "";
			if (Utility.file_exists(theme.InfoFile)){
				info = Utility.read_file(theme.InfoFile);
			}
			
			Utility.messagebox_show("[" + _("Info") + "] " + theme.Name, info);
		}
	}
	
	private void btnThemePreview_clicked () {
		ConkyTheme theme = tvTheme_get_selected_theme();;
		if (theme != null){
			
			try{
				//Gdk.Pixbuf px = new Gdk.Pixbuf.from_file_at_size (theme.PreviewImage, 400, 200);
				Gdk.Pixbuf px = new Gdk.Pixbuf.from_file (theme.PreviewImage);
				
				var dlg = new Window();
				dlg.modal = true;
				dlg.skip_pager_hint = true;
				dlg.skip_taskbar_hint = true;
				dlg.type_hint = Gdk.WindowTypeHint.MENU;
				dlg.window_position = Gtk.WindowPosition.CENTER;
				dlg.resizable = false;
				dlg.has_resize_grip = false;
				dlg.title = "[" + _("Preview") + "] " + theme.Name;
				var vboxImage = new Box (Orientation.VERTICAL, 6);
				dlg.add(vboxImage);
				var imgPreview = new Image();
				
				EventBox ebox = new EventBox();
				ebox.button_press_event.connect(() => { dlg.destroy(); return true;});
				ebox.add(imgPreview);
				vboxImage.add(ebox);
				
				imgPreview.pixbuf = px;
				
				dlg.show_all();
			}
			catch(Error e){
				log_error (e.message);
			}
		}
	}
	
	// tbOptions handlers -------------------------
	
	private void chkStartup_clicked ()
	{
		App.autostart(chkStartup.active);
	}
}
