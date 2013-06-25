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

	private Label lblAboutTab;
	private Box vboxAbout;

	private Label lblAppName;
	private Label lblAppVersion;
	private Label lblAuthor;
	private LinkButton lnkBlog;
	
	private Label lblHeaderStartup;
	private CheckButton chkStartup;
	
	private Label lblHeaderWidget;
	private Label lblBackgroundColor;
	private Label lblHeaderLocation;
	private Label lblAlignment;
	private Label lblGapX;
	private Label lblGapY;
	private Label lblEditWidgetStatus;
	private Label lblHeaderBackground;
	private Label lblTransparency;
	private Label lblMinWidth;
	private Label lblMinHeight;
	private ComboBox cmbAlignment;
	private ComboBox cmbWidget;
	private SpinButton spinGapX;
	private SpinButton spinGapY;
	private SpinButton spinTransparency;
	private SpinButton spinMinWidth;
	private SpinButton spinMinHeight;
	private ColorButton cbtnBackgroundColor;
	
	private TreeView tvTheme;
	private ScrolledWindow swTheme;
	
	private TreeView tvConfig;
	private ScrolledWindow swConfig;

	private Button btnThemeInfo;
	private Button btnThemePreview;
	private Button btnReloadThemes;
	private Button btnEditApplyChanges;
	private Button btnEditDiscardChanges;
	private Button btnEditReloadWidget;
	
	private Label lblHeaderKillConky;
	private Button btnKillConky;
	
	//private ComboBox comboTheme;

	public MainWindow() {
		this.title = AppName + " v" + AppVersion + " by " + AppAuthor + " (" + "teejeetech.blogspot.in" + ")";
        this.window_position = WindowPosition.CENTER;
        this.destroy.connect (Gtk.main_quit);
        set_default_size (600, 20);	

		//tabMain
        tabMain = new Notebook ();
		tabMain.margin = 6;
		add(tabMain);
		
		//vboxTheme
        vboxTheme = new Box (Orientation.VERTICAL, 6);
		vboxTheme.margin = 6;

        //lblThemeTab
		lblThemeTab = new Label (_("Theme"));

		tabMain.append_page (vboxTheme, lblThemeTab);
		
        //hboxTheme
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
		
		//Theme Name Column
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
		
		//'Enabled' Column
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
		
		//Theme Name Column
		colName = new TreeViewColumn();
		colName.title = _("Widget");
		colName.resizable = true;
		colName.expand = true;
		
		cellName = new CellRendererText ();
		cellName.ellipsize = Pango.EllipsizeMode.END;
		cellName.width = 200;
		colName.pack_start (cellName, false);
		colName.set_cell_data_func (cellName, tvConfig_cellName_render);
		tvConfig.append_column(colName);
		
		//'Enabled' Column
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

		//btnReloadThemes
		btnReloadThemes = new Button.with_label(_("Refresh List"));
		btnReloadThemes.set_image (new Image.from_stock (Stock.REFRESH, IconSize.MENU));
        btnReloadThemes.clicked.connect (() => {
			App.reload_themes();
			this.load_themes();
			});
        btnReloadThemes.set_tooltip_text (_("Reload list of themes"));
		hboxThemeButtons.add(btnReloadThemes);
		
		//Options tab ---------------------------
		
		//vboxOptions
        vboxOptions = new Box (Orientation.VERTICAL, 6);
		vboxOptions.margin = 12;

        //lblOptionsTab
		lblOptionsTab = new Label (_("Options"));

		tabMain.append_page (vboxOptions, lblOptionsTab);

        //lblHeaderStartup
		lblHeaderStartup = new Gtk.Label("<b>" + _("Startup") + "</b>");
		lblHeaderStartup.set_use_markup(true);
		lblHeaderStartup.xalign = (float) 0.0;
		//lblHeaderStartup.margin_top = 6;
		lblHeaderStartup.margin_bottom = 6;
		vboxOptions.add(lblHeaderStartup);
		
		//chkStartup
		chkStartup = new CheckButton.with_label (_("Run Conky at system startup"));
		chkStartup.active = App.check_startup();
		chkStartup.clicked.connect (chkStartup_clicked);
		chkStartup.margin_left = 6;
		chkStartup.margin_bottom = 12;
		vboxOptions.add(chkStartup);
		
		//lblHeaderKillConky
		lblHeaderKillConky = new Gtk.Label("<b>" + _("Commands") + "</b>");
		lblHeaderKillConky.set_use_markup(true);
		lblHeaderKillConky.xalign = (float) 0.0;
		lblHeaderKillConky.margin_bottom = 6;
		vboxOptions.add(lblHeaderKillConky);
		
		//hboxCommands
        Box hboxCommands = new Box (Orientation.HORIZONTAL, 6);
        vboxOptions.add(hboxCommands);
        
		//btnKillConky
		btnKillConky = new Button.with_label("  " + _("Kill Conky"));
		btnKillConky.set_image (new Image.from_stock (Stock.STOP, IconSize.MENU));
        btnKillConky.clicked.connect (() => {
			App.kill_all_conky();
			});
        btnKillConky.set_tooltip_text (_("Kill all running Conky instances"));
        btnKillConky.set_size_request(150,30);
        btnKillConky.margin_left = 6;
        btnKillConky.expand = false;
		hboxCommands.add(btnKillConky);

        //Edit tab ---------------------------
		
        //lblEditTab
		lblEditTab = new Label (_("Edit"));

		//gridEdit
        Grid gridEdit = new Grid ();
        gridEdit.set_column_spacing (6);
        gridEdit.set_row_spacing (6);
        gridEdit.column_homogeneous = false;
        gridEdit.visible = false;
        gridEdit.margin = 12;
        tabMain.append_page (gridEdit, lblEditTab);
        
        int row=-1;
        int grid_col_count = 7;
        
        CellRendererText textCell;
        
        //lblHeaderWidget
		lblHeaderWidget = new Gtk.Label("<b>" + _("Widget") + "</b>");
		lblHeaderWidget.set_use_markup(true);
		lblHeaderWidget.xalign = (float) 0.0;
		lblHeaderWidget.margin_bottom = 6;
		gridEdit.attach(lblHeaderWidget,0,++row,grid_col_count,1);
		
        //cmbWidget
		cmbWidget = new ComboBox();
		textCell = new CellRendererText();
        cmbWidget.pack_start( textCell, false );
        cmbWidget.set_attributes( textCell, "text", 0 );
        cmbWidget.changed.connect(cmbWidget_changed);
        cmbWidget.margin_left = 6;
        gridEdit.attach(cmbWidget,0,++row,4,1);
		
        //btnEditReloadWidget
		btnEditReloadWidget = new Button.with_label("");
		btnEditReloadWidget.set_image (new Image.from_stock (Stock.REFRESH, IconSize.MENU));
        btnEditReloadWidget.clicked.connect (btnEditReloadWidget_clicked);
        btnEditReloadWidget.set_tooltip_text (_("Start / Restart widget"));
        btnEditReloadWidget.set_size_request(40,30);
		gridEdit.attach(btnEditReloadWidget,4,row,1,1);

		//lblEditWidgetStatus
		lblEditWidgetStatus = new Gtk.Label("");
		lblEditWidgetStatus.xalign = (float) 0.5;
		lblEditWidgetStatus.set_use_markup(true);
		gridEdit.attach(lblEditWidgetStatus,5,row,1,1);

		//lblHeaderLocation
		lblHeaderLocation = new Gtk.Label("<b>" + _("Location") + "</b>");
		lblHeaderLocation.set_use_markup(true);
		lblHeaderLocation.xalign = (float) 0.0;
		lblHeaderLocation.margin_top = 12;
		lblHeaderLocation.margin_bottom = 6;
		gridEdit.attach(lblHeaderLocation,0,++row,grid_col_count,1);
		
		//lblAlignment
		lblAlignment = new Gtk.Label(_("Alignment"));
		lblAlignment.margin_left = 6;
		lblAlignment.xalign = (float) 0.0;
		gridEdit.attach(lblAlignment,0,++row,2,1);
		
		//cmbAlignment
		cmbAlignment = new ComboBox();
		textCell = new CellRendererText();
        cmbAlignment.pack_start( textCell, false );
        cmbAlignment.set_attributes( textCell, "text", 0 );
        gridEdit.attach(cmbAlignment,2,row,2,1);
		
		//populate
		TreeIter iter;
		ListStore model = new Gtk.ListStore (2, typeof (string), typeof (string));
		model.append (out iter);
		model.set (iter,0,_("Top Left"),1,"top_left");
		model.append (out iter);
		model.set (iter,0,_("Top Right"),1,"top_right");
		model.append (out iter);
		model.set (iter,0,_("Top Middle"),1,"top_middle");
		model.append (out iter);
		model.set (iter,0,_("Bottom Left"),1,"bottom_left");
		model.append (out iter);
		model.set (iter,0,_("Bottom Right"),1,"bottom_right");
		model.append (out iter);
		model.set (iter,0,_("Bottom Middle"),1,"bottom_middle");
		model.append (out iter);
		model.set (iter,0,_("Middle Left"),1,"middle_left");
		model.append (out iter);
		model.set (iter,0,_("Middle Right"),1,"middle_right");
		model.append (out iter);
		model.set (iter,0,_("Middle Middle"),1,"middle_middle");
		cmbAlignment.set_model(model);
		
		//lblGapX
		lblGapX = new Gtk.Label(_("Horizontal Gap"));
		lblGapX.set_tooltip_text("[GAP_X] Horizontal distance from window border");
		lblGapX.margin_left = 6;
		lblGapX.xalign = (float) 0.0;
		gridEdit.attach(lblGapX,0,++row,2,1);
		
		//spinGapX
		spinGapX = new SpinButton.with_range(-10000,10000,10);
		spinGapX.xalign = (float) 0.5;
		spinGapX.value = 0.0;
		gridEdit.attach(spinGapX,2,row,1,1);
		
		//lblGapY
		lblGapY = new Gtk.Label(_("Vertical Gap"));
		lblGapY.set_tooltip_text("[GAP_Y] Vertical distance from window border");
		lblGapY.margin_left = 6;
		lblGapY.xalign = (float) 0.0;
		gridEdit.attach(lblGapY,0,++row,2,1);
		
		//spinGapY
		spinGapY = new SpinButton.with_range(-10000,10000,10);
		spinGapY.xalign = (float) 0.5;
		spinGapY.value = 0.0;
		gridEdit.attach(spinGapY,2,row,1,1);

		//lblHeaderBackground
		lblHeaderBackground = new Gtk.Label("<b>" + _("Background") + "</b>");
		lblHeaderBackground.set_use_markup(true);
		lblHeaderBackground.xalign = (float) 0.0;
		lblHeaderBackground.margin_top = 12;
		lblHeaderBackground.margin_bottom = 6;
		gridEdit.attach(lblHeaderBackground,0,++row,grid_col_count,1);
		
		string tt = _("Background transparency \n0   = Fully Opaque, \n100 = Fully Transparent");
		
		//lblTransparency
		lblTransparency = new Gtk.Label(_("Transparency (%)"));
		lblTransparency.set_tooltip_text(tt);
		lblTransparency.margin_left = 6;
		lblTransparency.xalign = (float) 0.0;
		gridEdit.attach(lblTransparency,0,++row,2,1);
		
		//spinTransparency
		spinTransparency = new SpinButton.with_range(0,100,10);
		spinTransparency.set_tooltip_text(tt);
		spinTransparency.xalign = (float) 0.5;
		spinTransparency.value = 100.0;
		gridEdit.attach(spinTransparency,2,row,1,1);
		
		//lblTransparency
		lblBackgroundColor = new Gtk.Label(_("Background Color"));
		lblBackgroundColor.margin_left = 6;
		lblBackgroundColor.xalign = (float) 0.0;
		gridEdit.attach(lblBackgroundColor,0,++row,2,1);
		
		//cbtnBackgroundColor
		cbtnBackgroundColor = new ColorButton();
		gridEdit.attach(cbtnBackgroundColor,2,row,1,1);
		
		//lblMinWidth
		lblMinWidth = new Gtk.Label(_("Minimum Width"));
		lblMinWidth.margin_left = 6;
		lblMinWidth.xalign = (float) 0.0;
		gridEdit.attach(lblMinWidth,0,++row,2,1);
		
		//spinMinWidth
		spinMinWidth = new SpinButton.with_range(0,9999,10);
		spinMinWidth.xalign = (float) 0.5;
		spinMinWidth.value = 100.0;
		spinMinWidth.set_tooltip_text(_("Minimum Width"));
		gridEdit.attach(spinMinWidth,2,row,1,1);
		
		//lblMinHeight
		lblMinHeight = new Gtk.Label(_("Minimum Height"));
		lblMinHeight.margin_left = 6;
		lblMinHeight.xalign = (float) 0.0;
		gridEdit.attach(lblMinHeight,0,++row,2,1);
		
		//spinMinHeight
		spinMinHeight = new SpinButton.with_range(0,9999,10);
		spinMinHeight.xalign = (float) 0.5;
		spinMinHeight.value = 100.0;
		spinMinHeight.set_tooltip_text(_("Minimum Height"));
		gridEdit.attach(spinMinHeight,2,row,1,1);
		
		//hboxCommands
        Box hboxEditButtons = new Box (Orientation.HORIZONTAL, 6);
        hboxEditButtons.homogeneous = true;
        hboxEditButtons.margin_top = 12;
        hboxEditButtons.vexpand = true;
        hboxEditButtons.valign = Align.END;
        gridEdit.attach(hboxEditButtons,0,++row,4,1);
        
		//btnEditApplyChanges
		btnEditApplyChanges = new Button.with_label("  " + _("Apply Changes"));
		btnEditApplyChanges.set_image (new Image.from_stock (Stock.APPLY, IconSize.MENU));
        btnEditApplyChanges.clicked.connect (btnEditApplyChanges_clicked);
        btnEditApplyChanges.set_tooltip_text (_("Apply Changes"));
        btnEditApplyChanges.set_size_request(-1,30);
		hboxEditButtons.add(btnEditApplyChanges);
		
		//btnEditDiscardChanges
		btnEditDiscardChanges = new Button.with_label("  " + _("Discard"));
		btnEditDiscardChanges.set_image (new Image.from_stock (Stock.CANCEL, IconSize.MENU));
        btnEditDiscardChanges.clicked.connect (btnEditDiscardChanges_clicked);
        btnEditDiscardChanges.set_tooltip_text (_("Apply Changes"));
        btnEditDiscardChanges.set_size_request(-1,30);
		hboxEditButtons.add(btnEditDiscardChanges);
		
		//About tab ---------------------------
		
		//vboxAbout
        vboxAbout = new Box (Orientation.VERTICAL, 6);
		vboxAbout.margin = 12;

        //lblAboutTab
		lblAboutTab = new Label (_("About"));

		tabMain.append_page (vboxAbout, lblAboutTab);
		
        //lblAppName
		lblAppName = new Gtk.Label("""<span size="x-large" weight="bold">""" + AppName + "</span>");
		lblAppName.set_use_markup(true);
		lblAppName.xalign = (float) 0.0;
		lblAppName.margin_top = 0;
		lblAppName.margin_bottom = 6;
		vboxAbout.add(lblAppName);
		
		lblAppVersion = new Gtk.Label(_("Version") + ": " + AppVersion);
		lblAppVersion.set_use_markup(true);
		lblAppVersion.xalign = (float) 0.0;
		vboxAbout.add(lblAppVersion);
		
		lblAuthor = new Gtk.Label("(c) 2013, " + AppAuthor + " (" + AppAuthorEmail + ")");
		lblAuthor.set_use_markup(true);
		lblAuthor.xalign = (float) 0.0;
		vboxAbout.add(lblAuthor);
		
		lnkBlog = new Gtk.LinkButton("http://teejeetech.blogspot.in");
		lnkBlog.xalign = (float) 0.0;
		lnkBlog.uri = "http://teejeetech.blogspot.in";
		vboxAbout.add(lnkBlog);
		
		lnkBlog.activate_link.connect(() => { 
			Posix.system("xdg-open \"http://teejeetech.blogspot.in\"");
			return true;
		});
        
		load_themes();
	}

	public void load_themes() {

		ListStore model;
		TreeIter iter;
		
		//populate tvTheme
		model = new ListStore(1,typeof(ConkyTheme));
		foreach(ConkyTheme theme in App.ThemeList) {
			model.append(out iter);
			model.set(iter, 0, theme);
		}
		tvTheme.model = model;
		
		//populate cmbWidget
		model = new Gtk.ListStore (2, typeof (string), typeof (ConkyConfig));
		foreach(ConkyTheme theme in App.ThemeList) {
			foreach(ConkyConfig conf in theme.ConfigList) {
				model.append(out iter);
				model.set(iter, 0, theme.Name + " - " + conf.Name, 1, conf);
			}
		}
		cmbWidget.set_model(model);
		cmbWidget.set_active (0);
	}
	
	//Edit tab handlers ----------

	private void cmbWidget_changed () {
		TreeIter iter;
		ConkyConfig conf;

		if (cmbWidget.active == -1){
			set_editing_options_enabled(false);
			return;
		}
		else{
			set_editing_options_enabled(true);
		}
		
		cmbWidget.get_active_iter(out iter);
		(cmbWidget.model).get(iter, 1, out conf);
		
		if (conf.Enabled){
			lblEditWidgetStatus.label = "<span foreground=\"green\">[" + _("Running") + "]</span>";
			//lblEditWidgetStatus.
		}
		else{
			lblEditWidgetStatus.label = "<span foreground=\"brown\">[" + _("Stopped") + "]</span>";
		}
		
		Utility.gtk_combobox_set_value(cmbAlignment, 1, conf.alignment);
		spinGapX.value = double.parse(conf.gap_x);
		spinGapY.value = double.parse(conf.gap_y);
		
		if (conf.own_window_transparent == "yes"){
			spinTransparency.value = 100;
		}
		else if (conf.own_window_argb_value == ""){
			spinTransparency.value = 100;
		}
		else{
			spinTransparency.value = ((255.0 - int.parse(conf.own_window_argb_value)) / 255.0) * 100;
		}
		
		cbtnBackgroundColor.rgba = Utility.hex_to_rgba(conf.own_window_colour);
		
		string size = conf.minimum_size;
		spinMinWidth.value = int.parse(size.split(" ")[0]);
		spinMinHeight.value = int.parse(size.split(" ")[1]);
	}
	
	private void btnEditApplyChanges_clicked () {
		TreeIter iter;
		ConkyConfig conf;
		
		cmbWidget.get_active_iter(out iter);
		(cmbWidget.model).get(iter, 1, out conf);
		
		conf.alignment = Utility.gtk_combobox_get_value(cmbAlignment,1,"top_left");
		conf.gap_x = spinGapX.value.to_string();
		conf.gap_y = spinGapY.value.to_string();
		
		conf.own_window_argb_value = "%.0f".printf(((100.0 - spinTransparency.value) / 100.0) * 255.0);
		conf.own_window_colour = Utility.rgba_to_hex(cbtnBackgroundColor.rgba, false, false);  
		conf.minimum_size = spinMinWidth.value.to_string() + " " + spinMinHeight.value.to_string();
	}
	
	private void btnEditDiscardChanges_clicked () {
		cmbWidget_changed();
	}
	
	private void btnEditReloadWidget_clicked () {
		TreeIter iter;
		ConkyConfig conf;
		
		cmbWidget.get_active_iter(out iter);
		(cmbWidget.model).get(iter, 1, out conf);
		
		if (conf.Enabled) {
			conf.stop_conky();
		}
		
		conf.start_conky();
	}
	
	private void set_editing_options_enabled (bool enable){
		btnEditReloadWidget.sensitive = enable;
		lblEditWidgetStatus.label = "";
		cmbAlignment.sensitive = enable;
		spinGapX.sensitive = enable;
		spinGapY.sensitive = enable;
		spinTransparency.sensitive = enable;
		cbtnBackgroundColor.sensitive = enable;
		spinMinWidth.sensitive = enable;
		spinMinHeight.sensitive = enable;
		btnEditApplyChanges.sensitive = enable;
		btnEditDiscardChanges.sensitive = enable;
	}
	
	//tvTheme Handlers -----------
	
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
		
		//populate config list ----------
		
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
		
		//set preview and info buttons ---------
		
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
	
	//tvConfig Handlers -----------
	
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
	
	//hboxThemeButtons ------------------------
	
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
	
	//tbOptions handlers -------------------------
	
	private void chkStartup_clicked ()
	{
		App.autostart(chkStartup.active);
	}
}
