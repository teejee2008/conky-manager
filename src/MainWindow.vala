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
	private Notebook tabWidgetProperties;
	
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
	private Label lblHeaderThemePack;
	private Button btnInstallThemePack;
	
	private Label lblHeaderWidget;
	private Label lblBackgroundColor;
	private Label lblAlignment;
	private Label lblGapX;
	private Label lblGapY;
	private Label lblTransparency;
	private Label lblMinWidth;
	private Label lblMinHeight;
	private Label lblWidgetTimeNotFound;
	private Label lblWidgetNetworkNotFound;
	private ComboBox cmbAlignment;
	private ComboBox cmbWidget;
	private ComboBox cmbTransparencyType;
	private ComboBox cmbTimeFormat;
	private SpinButton spinGapX;
	private SpinButton spinGapY;
	private SpinButton spinOpacity;
	private SpinButton spinMinWidth;
	private SpinButton spinMinHeight;
	private SpinButton spinHeightPadding;
	private ColorButton cbtnBackgroundColor;
	private Entry txtNetworkDevice;
	private Button btnWiFi;
	private Button btnLAN;
	private Button btnShowDesktop;
	
	private TreeView tvTheme;
	private ScrolledWindow swTheme;
	
	private TreeView tvConfig;
	private ScrolledWindow swConfig;

	private Button btnThemeInfo;
	private Button btnThemePreview;
	private Button btnReloadThemes;
	private Button btnApplyChanges;
	private Button btnDiscardChanges;

	private Label lblHeaderKillConky;
	private Button btnKillConky;

	public MainWindow() {
		this.title = AppName + " v" + AppVersion + " by " + AppAuthor + " (" + "teejeetech.blogspot.in" + ")";
        this.window_position = WindowPosition.CENTER;
        this.destroy.connect (Gtk.main_quit);
        set_default_size (600, 20);	

		//set app icon
		try{
			this.icon = new Gdk.Pixbuf.from_file ("""/usr/share/pixmaps/conky-manager.png""");
		}
        catch(Error e){
	        log_error (e.message);
	    }
	    
		//tabMain
        tabMain = new Notebook ();
		tabMain.margin = 6;
		tabMain.switch_page.connect(tabMain_switch_page);
		add(tabMain);
		
		//vboxTheme
        vboxTheme = new Box (Orientation.VERTICAL, 6);
		vboxTheme.margin = 6;

        //lblThemeTab
		lblThemeTab = new Label (_("Theme"));

		tabMain.append_page (vboxTheme, lblThemeTab);

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

        CellRendererText textCell;
        
        //lblHeaderWidget
		lblHeaderWidget = new Gtk.Label("<b>" + _("Widget") + "</b>");
		lblHeaderWidget.set_use_markup(true);
		lblHeaderWidget.xalign = (float) 0.0;
		lblHeaderWidget.margin_bottom = 6;
		gridEdit.attach(lblHeaderWidget,0,0,2,1);
		
        //cmbWidget
		cmbWidget = new ComboBox();
		textCell = new CellRendererText();
        cmbWidget.pack_start( textCell, false );
        cmbWidget.set_attributes( textCell, "text", 0 );
        cmbWidget.changed.connect(cmbWidget_changed);
        cmbWidget.margin_left = 6;
        cmbWidget.margin_right = 6;
        cmbWidget.hexpand = true;
        gridEdit.attach(cmbWidget,0,1,1,1);
		
		//btnShowDesktop
        btnShowDesktop = new Button.with_label(_("Show Desktop"));
        btnShowDesktop.clicked.connect (() => {
			//show desktop
			App.minimize_all_other_windows();
			});
		btnShowDesktop.set_size_request(130,-1);
        btnShowDesktop.set_tooltip_text (_("Minimize all windows and show the widget on the desktop"));
		gridEdit.attach(btnShowDesktop,1,1,1,1);
		
		//lblHeaderWidgetProperties
		Label lblHeaderWidgetProperties = new Gtk.Label("<b>" + _("Properties") + "</b>");
		lblHeaderWidgetProperties.set_use_markup(true);
		lblHeaderWidgetProperties.xalign = (float) 0.0;
		lblHeaderWidgetProperties.margin_top = 6;
		gridEdit.attach(lblHeaderWidgetProperties,0,2,2,1);
		
        //tabWidgetProperties ---------------------------------------
        tabWidgetProperties = new Notebook ();
		tabWidgetProperties.margin = 6;
		tabWidgetProperties.tab_pos = PositionType.LEFT;
		tabWidgetProperties.expand = true;
		gridEdit.attach(tabWidgetProperties,0,3,2,1);
		
		//lblWidgetLocation
		Label lblWidgetLocation = new Label (_("Location"));

		//gridWidgetLocation -----------------------------------------------
		
        Grid gridWidgetLocation = new Grid ();
        gridWidgetLocation.set_column_spacing (12);
        gridWidgetLocation.set_row_spacing (6);
        gridWidgetLocation.column_homogeneous = false;
        gridWidgetLocation.visible = false;
        gridWidgetLocation.margin = 12;
        tabWidgetProperties.append_page (gridWidgetLocation, lblWidgetLocation);
        
		int row = -1;
		
		//lblAlignment
		lblAlignment = new Gtk.Label(_("Alignment"));
		lblAlignment.margin_left = 6;
		lblAlignment.xalign = (float) 0.0;
		gridWidgetLocation.attach(lblAlignment,0,++row,1,1);
		
		//cmbAlignment
		cmbAlignment = new ComboBox();
		textCell = new CellRendererText();
        cmbAlignment.pack_start( textCell, false );
        cmbAlignment.set_attributes( textCell, "text", 0 );
        gridWidgetLocation.attach(cmbAlignment,1,row,1,1);
		
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
		lblGapX.set_tooltip_text("[GAP_X] Horizontal distance from window border (in pixels)");
		lblGapX.margin_left = 6;
		lblGapX.xalign = (float) 0.0;
		gridWidgetLocation.attach(lblGapX,0,++row,1,1);
		
		//spinGapX
		spinGapX = new SpinButton.with_range(-10000,10000,10);
		spinGapX.xalign = (float) 0.5;
		spinGapX.value = 0.0;
		gridWidgetLocation.attach(spinGapX,1,row,1,1);
		
		//lblGapY
		lblGapY = new Gtk.Label(_("Vertical Gap"));
		lblGapY.set_tooltip_text("[GAP_Y] Vertical distance from window border (in pixels)");
		lblGapY.margin_left = 6;
		lblGapY.xalign = (float) 0.0;
		gridWidgetLocation.attach(lblGapY,0,++row,1,1);
		
		//spinGapY
		spinGapY = new SpinButton.with_range(-10000,10000,10);
		spinGapY.xalign = (float) 0.5;
		spinGapY.value = 0.0;
		spinGapY.set_size_request(120,-1);
		gridWidgetLocation.attach(spinGapY,1,row,1,1);
		
		//lblWidgetTransparency
		Label lblWidgetTransparency = new Label (_("Transparency"));

		//gridWidgetTransparency  -----------------------------------------------------------
		
        Grid gridWidgetTransparency = new Grid ();
        gridWidgetTransparency.set_column_spacing (12);
        gridWidgetTransparency.set_row_spacing (6);
        gridWidgetTransparency.column_homogeneous = false;
        gridWidgetTransparency.visible = false;
        gridWidgetTransparency.margin = 12;
        tabWidgetProperties.append_page (gridWidgetTransparency, lblWidgetTransparency);
        
        row = -1;
        
		string tt = "";
		
        //lblBackgroundType
		Label lblBackgroundType = new Gtk.Label(_("Transparency Type"));
		lblBackgroundType.margin_left = 6;
		lblBackgroundType.xalign = (float) 0.0;
		lblBackgroundType.set_tooltip_text(tt);
		lblBackgroundType.set_use_markup(true);
		gridWidgetTransparency.attach(lblBackgroundType,0,row,1,1);
		
        //cmbTransparencyType
		cmbTransparencyType = new ComboBox();
		textCell = new CellRendererText();
        cmbTransparencyType.pack_start( textCell, false );
        cmbTransparencyType.set_attributes( textCell, "text", 0 );
        cmbTransparencyType.changed.connect(cmbTransparencyType_changed);
		cmbTransparencyType.set_tooltip_text(tt);
        gridWidgetTransparency.attach(cmbTransparencyType,1,row,2,1);
		
		//populate
		model = new Gtk.ListStore (2, typeof (string), typeof (string));
		model.append (out iter);
		model.set (iter,0,_("Opaque"),1,"opaque");
		model.append (out iter);
		model.set (iter,0,_("Transparent"),1,"trans");
		model.append (out iter);
		model.set (iter,0,_("Pseudo-Transparent"),1,"pseudo");
		model.append (out iter);
		model.set (iter,0,_("Semi-Transparent"),1,"semi");
		cmbTransparencyType.set_model(model);

		tt = _("Window Opacity\n\n0 = Fully Transparent, 100 = Fully Opaque");
		
		//lblTransparency
		lblTransparency = new Gtk.Label(_("Opacity (%)"));
		lblTransparency.set_tooltip_text(tt);
		lblTransparency.margin_left = 6;
		lblTransparency.xalign = (float) 0.0;
		gridWidgetTransparency.attach(lblTransparency,0,++row,1,1);
		
		//spinOpacity
		spinOpacity = new SpinButton.with_range(0,100,10);
		spinOpacity.set_tooltip_text(tt);
		spinOpacity.xalign = (float) 0.5;
		spinOpacity.value = 100.0;
		//spinOpacity.set_size_request(120,-1);
		gridWidgetTransparency.attach(spinOpacity,1,row,1,1);
		
		//lblBackgroundColor
		lblBackgroundColor = new Gtk.Label(_("Background Color"));
		lblBackgroundColor.margin_left = 6;
		lblBackgroundColor.xalign = (float) 0.0;
		gridWidgetTransparency.attach(lblBackgroundColor,0,++row,1,1);
		
		//cbtnBackgroundColor
		cbtnBackgroundColor = new ColorButton();
		gridWidgetTransparency.attach(cbtnBackgroundColor,1,row,1,1);
		
		//lblTransparencyExpander
		Label lblTransparencyExpander = new Gtk.Label("");
		lblTransparencyExpander.margin_left = 6;
		lblTransparencyExpander.vexpand = true;
		gridWidgetTransparency.attach(lblTransparencyExpander,0,++row,3,1);
		
		tt = "Ø " + _("Setting Type to \"Transparent\" will make the whole window transparent (including any images). Use \"Pseudo-Transparent\" if you want the images to be opaque.");
		
		//lblSize1
		Label lblTrans1 = new Gtk.Label(tt);
		lblTrans1.margin_left = 6;
		lblTrans1.margin_bottom = 6;
		lblTrans1.xalign = (float) 0.0;
		lblTrans1.set_size_request(100,-1);
		lblTrans1.set_line_wrap(true);
		gridWidgetTransparency.attach(lblTrans1,0,++row,3,1);
		
		tt = "Ø " + _("Setting Type to \"Pseudo-Transparent\" will make the window transparent but the window will have a shadow. The shadow can be disabled by configuring your window manager.");
		
		//lblSize1
		Label lblTrans2 = new Gtk.Label(tt);
		lblTrans2.margin_left = 6;
		lblTrans2.margin_bottom = 6;
		lblTrans2.xalign = (float) 0.0;
		lblTrans2.set_size_request(100,-1);
		lblTrans2.set_line_wrap(true);
		gridWidgetTransparency.attach(lblTrans2,0,++row,3,1);
		
		//lblWidgetSize
		Label lblWidgetSize = new Label (_("Size"));

		//gridWidgetSize  -----------------------------------------------------------
		
        Grid gridWidgetSize = new Grid ();
        gridWidgetSize.set_column_spacing (12);
        gridWidgetSize.set_row_spacing (6);
        gridWidgetSize.column_homogeneous = false;
        gridWidgetSize.visible = false;
        gridWidgetSize.margin = 12;
        gridWidgetSize.border_width = 1;
        tabWidgetProperties.append_page (gridWidgetSize, lblWidgetSize);
        
        row = -1;
        
        tt = _("Width should be larger than the size of window contents,\notherwise this setting will not have any effect");
		
		//lblMinWidth
		lblMinWidth = new Gtk.Label(_("Minimum Width"));
		lblMinWidth.margin_left = 6;
		lblMinWidth.xalign = (float) 0.0;
		lblMinWidth.set_tooltip_text(tt);
		gridWidgetSize.attach(lblMinWidth,0,++row,1,1);
		
		//spinMinWidth
		spinMinWidth = new SpinButton.with_range(0,9999,10);
		spinMinWidth.xalign = (float) 0.5;
		spinMinWidth.value = 100.0;
		spinMinWidth.set_size_request(120,-1);
		spinMinWidth.set_tooltip_text(tt);
		gridWidgetSize.attach(spinMinWidth,1,row,1,1);
		
		tt = _("Height should be larger than the size of window contents,\notherwise this setting will not have any effect");
		
		//lblMinHeight
		lblMinHeight = new Gtk.Label(_("Minimum Height"));
		lblMinHeight.margin_left = 6;
		lblMinHeight.xalign = (float) 0.0;
		lblMinHeight.set_tooltip_text(tt);
		gridWidgetSize.attach(lblMinHeight,0,++row,1,1);
		
		//spinMinHeight
		spinMinHeight = new SpinButton.with_range(0,9999,10);
		spinMinHeight.xalign = (float) 0.5;
		spinMinHeight.value = 100.0;
		spinMinHeight.set_tooltip_text(tt);
		gridWidgetSize.attach(spinMinHeight,1,row,1,1);
		
		tt = _("Increases the window height by adding empty lines at the end of the Conky config file");
		
		//lblTrailingLines
		Label lblTrailingLines = new Gtk.Label(_("Height Padding"));
		lblTrailingLines.margin_left = 6;
		lblTrailingLines.xalign = (float) 0.0;
		lblTrailingLines.set_tooltip_text(tt);
		gridWidgetSize.attach(lblTrailingLines,0,++row,1,1);
		
		//spinHeightPadding
		spinHeightPadding = new SpinButton.with_range(0,100,1);
		spinHeightPadding.xalign = (float) 0.5;
		spinHeightPadding.value = 0.0;
		spinHeightPadding.set_tooltip_text(tt);
		gridWidgetSize.attach(spinHeightPadding,1,row,1,1);
		
		//lblSizeExpander
		Label lblSizeExpander = new Gtk.Label("");
		lblSizeExpander.margin_left = 6;
		lblSizeExpander.vexpand = true;
		gridWidgetSize.attach(lblSizeExpander,0,++row,3,1);
		
		tt = "Ø " + _("The minimum width & height must be more than the size of the window contents, otherwise the setting will not have any effect.");
		
		//lblSize1
		Label lblSize1 = new Gtk.Label(tt);
		lblSize1.margin_left = 6;
		lblSize1.margin_bottom = 6;
		lblSize1.xalign = (float) 0.0;
		lblSize1.set_size_request(100,-1);
		lblSize1.set_line_wrap(true);
		gridWidgetSize.attach(lblSize1,0,++row,3,1);
		
		tt = "Ø " + _("Setting Type to \"Opaque\" (from the transparency tab) will make it easier to see the changes");
		
		//lblSize2
		Label lblSize2 = new Gtk.Label(tt);
		lblSize2.margin_left = 6;
		lblSize2.margin_bottom = 6;
		lblSize2.xalign = (float) 0.0;
		lblSize2.set_size_request(100,-1);
		lblSize2.set_line_wrap(true);
		gridWidgetSize.attach(lblSize2,0,++row,3,1);
		
		//lblWidgetTime
		Label lblWidgetTime = new Label (_("Time"));

		//gridWidgetTime  -----------------------------------------------------------
		
        Grid gridWidgetTime = new Grid ();
        gridWidgetTime.set_column_spacing (12);
        gridWidgetTime.set_row_spacing (6);
        gridWidgetTime.column_homogeneous = false;
        gridWidgetTime.visible = false;
        gridWidgetTime.margin = 12;
        gridWidgetTime.border_width = 1;
        tabWidgetProperties.append_page (gridWidgetTime, lblWidgetTime);
		
		row = -1;
		
        //lblTimeFormat
		Label lblTimeFormat = new Gtk.Label(_("Time Format"));
		lblTimeFormat.margin_left = 6;
		lblTimeFormat.xalign = (float) 0.0;
		lblTimeFormat.set_use_markup(true);
		gridWidgetTime.attach(lblTimeFormat,0,++row,1,1);
		
        //cmbTimeFormat
		cmbTimeFormat = new ComboBox();
		textCell = new CellRendererText();
        cmbTimeFormat.pack_start( textCell, false );
        cmbTimeFormat.set_attributes( textCell, "text", 0 );
        gridWidgetTime.attach(cmbTimeFormat,1,row,1,1);
		
		//lblWidgetTimeNotFound
		lblWidgetTimeNotFound = new Gtk.Label("");
		lblWidgetTimeNotFound.set_use_markup(true);
		lblWidgetTimeNotFound.xalign = (float) 0.0;
		lblWidgetTimeNotFound.margin = 6;
		gridWidgetTime.attach(lblWidgetTimeNotFound,0,++row,2,1);
		
		//populate
		model = new Gtk.ListStore (2, typeof (string), typeof (string));
		model.append (out iter);
		model.set (iter,0,_("12 Hour"),1,"12");
		model.append (out iter);
		model.set (iter,0,_("24 Hour"),1,"24");
		cmbTimeFormat.set_model(model);
		
		//lblWidgetNetwork
		Label lblWidgetNetwork = new Label (_("Network"));

		//gridWidgetNetwork  -----------------------------------------------------------
		
        Grid gridWidgetNetwork = new Grid ();
        gridWidgetNetwork.set_column_spacing (12);
        gridWidgetNetwork.set_row_spacing (6);
        gridWidgetNetwork.column_homogeneous = false;
        gridWidgetNetwork.visible = false;
        gridWidgetNetwork.margin = 12;
        gridWidgetNetwork.border_width = 1;
        tabWidgetProperties.append_page (gridWidgetNetwork, lblWidgetNetwork);
		
		row = -1;

        //lblNetworkDevice
		Label lblNetworkDevice = new Gtk.Label(_("Interface"));
		lblNetworkDevice.margin_left = 6;
		lblNetworkDevice.xalign = (float) 0.0;
		lblNetworkDevice.set_use_markup(true);
		gridWidgetNetwork.attach(lblNetworkDevice,0,++row,1,1);
		
		//txtNetworkDevice
        txtNetworkDevice =  new Gtk.Entry();
        gridWidgetNetwork.attach(txtNetworkDevice,1,row,1,1);
        
        //btnWiFi
        btnWiFi = new Button.with_label(_("WiFi"));
        btnWiFi.clicked.connect (() => {
			txtNetworkDevice.text = "wlan0";
			});
		btnWiFi.set_size_request(50,-1);
        btnWiFi.set_tooltip_text (_("WiFi Network") + " (wlan0)");
		gridWidgetNetwork.attach(btnWiFi,2,row,1,1);
		
        //btnLAN
        btnLAN = new Button.with_label(_("LAN"));
        btnLAN.clicked.connect (() => {
			txtNetworkDevice.text = "eth0";
			});
		btnLAN.set_size_request(50,-1);
        btnLAN.set_tooltip_text (_("Wired LAN Network") + " (eth0)");
		gridWidgetNetwork.attach(btnLAN,3,row,1,1);

		//lblWidgetNetworkNotFound
		lblWidgetNetworkNotFound = new Gtk.Label("");
		lblWidgetNetworkNotFound.set_use_markup(true);
		lblWidgetNetworkNotFound.xalign = (float) 0.0;
		lblWidgetNetworkNotFound.margin = 6;
		gridWidgetNetwork.attach(lblWidgetNetworkNotFound,0,++row,4,1);
		
		//hboxCommands --------------------------------------------------
		
        Box hboxEditButtons = new Box (Orientation.HORIZONTAL, 6);
        hboxEditButtons.homogeneous = true;
        gridEdit.attach(hboxEditButtons,0,5,2,1);
        
		//btnApplyChanges
		btnApplyChanges = new Button.with_label("  " + _("Apply Changes"));
		btnApplyChanges.set_image (new Image.from_stock (Stock.APPLY, IconSize.MENU));
        btnApplyChanges.clicked.connect (btnApplyChanges_clicked);
        btnApplyChanges.set_tooltip_text (_("Apply Changes"));
        btnApplyChanges.set_size_request(-1,30);
		hboxEditButtons.add(btnApplyChanges);
		
		//btnDiscardChanges
		btnDiscardChanges = new Button.with_label("  " + _("Discard"));
		btnDiscardChanges.set_image (new Image.from_stock (Stock.CANCEL, IconSize.MENU));
        btnDiscardChanges.clicked.connect (btnDiscardChanges_clicked);
        btnDiscardChanges.set_tooltip_text (_("Apply Changes"));
        btnDiscardChanges.set_size_request(-1,30);
		hboxEditButtons.add(btnDiscardChanges);
		
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

		//lblHeaderThemePack
		lblHeaderThemePack = new Gtk.Label("<b>" + _("Theme Packs") + "</b>");
		lblHeaderThemePack.set_use_markup(true);
		lblHeaderThemePack.xalign = (float) 0.0;
		lblHeaderThemePack.margin_bottom = 6;
		vboxOptions.add(lblHeaderThemePack);
		
		//btnInstallThemePack
		btnInstallThemePack = new Button.with_label("  " + _("Import Conky Manager Theme Pack (*.cmtp.7z)"));
		btnInstallThemePack.set_image (new Image.from_stock (Stock.ADD, IconSize.MENU));
        btnInstallThemePack.clicked.connect (btnInstallThemePack_clicked);
        btnInstallThemePack.expand = false;
        btnInstallThemePack.set_size_request(500,30);
        btnInstallThemePack.margin_left = 6;
		vboxOptions.add(btnInstallThemePack);

		//lblHeaderKillConky
		lblHeaderKillConky = new Gtk.Label("<b>" + _("Commands") + "</b>");
		lblHeaderKillConky.set_use_markup(true);
		lblHeaderKillConky.xalign = (float) 0.0;
		lblHeaderKillConky.margin_top = 6;
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
        btnKillConky.set_size_request(200,30);
        btnKillConky.margin_left = 6;
        btnKillConky.expand = false;
		hboxCommands.add(btnKillConky);
		
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

		TreeModel model;
		TreeIter iter;
		ListStore store;
		ConkyTheme th;
		
		//get selected theme
		th = null;
		string name = "";
		if (tvTheme.get_selection().get_selected(out model, out iter)){
			model.get (iter, 0, out th, -1); //get theme
			name = th.Name;
		}

		//populate tvTheme
		TreeIter selected_iter = TreeIter();
		bool found = false;
		store = new ListStore(1,typeof(ConkyTheme));
		foreach(ConkyTheme theme in App.ThemeList) {
			store.append(out iter);
			store.set(iter, 0, theme);
			if (theme.Name == name){ 
				found = true; 
				selected_iter = iter;
			}
		}
		tvTheme.model = store;
		
		//re-select theme
		if(found){
			tvTheme.get_selection().select_iter(selected_iter);
		}

		//populate cmbWidget
		store = new Gtk.ListStore (2, typeof (string), typeof (ConkyConfig));
		foreach(ConkyTheme theme in App.ThemeList) {
			foreach(ConkyConfig conf in theme.ConfigList) {
				store.append(out iter);
				store.set(iter, 0, theme.Name + " - " + conf.Name, 1, conf);
			}
		}
		cmbWidget.set_model(store);
		cmbWidget.set_active (-1);
		set_editing_options_enabled(false);
		
		//store = new ListStore(1,typeof(ConkyConfig));
		//tvConfig.model = store;
	}
	
	//tabMain handlers ---------------------------
	
	private void tabMain_switch_page (Widget page, uint new_page) {
		uint old_page = tabMain.page;
		
		if ((cmbWidget == null) || (cmbWidget.model == null)){
			return;
		}
		
		if (new_page == 1){
			set_busy(true, this);

			//save active widgets
			if (App.EditMode == false){
				App.update_startup_script();
			}
			
			App.EditMode = true;
			
			set_busy(false, this);
		}
		else if(old_page == 1){
			set_busy(true, this);

			App.EditMode = false;
			
			if (cmbWidget.active != -1){
				//kill all widgets
				App.kill_all_conky();

				//restart saved widgets
				App.run_startup_script();
				
				cmbWidget.set_active (-1);
			}
		
			set_busy(false, this);
		}
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

		reload_widget_properties();
		
		if (tabMain.page == 1){
			set_busy(true, this);

			//kill all widgets
			App.kill_all_conky();

			//run selected widget
			conf.start_conky();
			
			//show desktop
			//App.minimize_all_other_windows();

			set_busy(false, this);
		}
	}
	
	private void reload_widget_properties(){
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
		
		debug("-----------------------------------------------------");
		debug(_("Load theme") + ": %s".printf(conf.Theme.Name + " - " + conf.Name));

		conf.read_file();
		
		//location
		Utility.gtk_combobox_set_value(cmbAlignment, 1, conf.alignment);
		spinGapX.value = double.parse(conf.gap_x);
		spinGapY.value = double.parse(conf.gap_y);
		
		string own_window_transparent = conf.own_window_transparent;
		string own_window_argb_visual = conf.own_window_argb_visual;
		string own_window_argb_value = conf.own_window_argb_value;
		
		//transparency
		if(own_window_transparent == "yes"){
			if(own_window_argb_visual == "yes"){
				//own_window_argb_value, if present, will be ignored by Conky
				Utility.gtk_combobox_set_value(cmbTransparencyType,1,"trans");
			}
			else if (own_window_argb_visual == "no"){
				Utility.gtk_combobox_set_value(cmbTransparencyType,1,"pseudo");
			}
			else{
				Utility.gtk_combobox_set_value(cmbTransparencyType,1,"pseudo");
			}
		}
		else if (own_window_transparent == "no"){
			if(own_window_argb_visual == "yes"){
				if (own_window_argb_value == "0"){
					Utility.gtk_combobox_set_value(cmbTransparencyType,1,"trans");
				}
				else if (own_window_argb_value == "255"){
					Utility.gtk_combobox_set_value(cmbTransparencyType,1,"opaque");
				}
				else{
					Utility.gtk_combobox_set_value(cmbTransparencyType,1,"semi");
				}
			}
			else if (own_window_argb_visual == "no"){
				Utility.gtk_combobox_set_value(cmbTransparencyType,1,"opaque");
			}
			else{
				Utility.gtk_combobox_set_value(cmbTransparencyType,1,"opaque");
			}
		}
		else{
			Utility.gtk_combobox_set_value(cmbTransparencyType,1,"opaque");
		}

		if (own_window_argb_value == ""){
			spinOpacity.value = 0;
		}
		else{
			spinOpacity.value = (int.parse(own_window_argb_value) / 255.0) * 100;
		}
		cbtnBackgroundColor.rgba = Utility.hex_to_rgba(conf.own_window_colour);
		
		//window size 
		string size = conf.minimum_size;
		spinMinWidth.value = int.parse(size.split(" ")[0]);
		spinMinHeight.value = int.parse(size.split(" ")[1]);
		spinHeightPadding.value = conf.height_padding;
		
		//time
		string time_format = conf.time_format;
		
		if (time_format == "") {
			cmbTimeFormat.sensitive = false;
			lblWidgetTimeNotFound.label = "<i>Ø " + _("Time format cannot be changed for selected widget") + "</i>";
		}
		else{
			cmbTimeFormat.sensitive = true;
			lblWidgetTimeNotFound.label = "";
		}
		
		if (time_format == "") { time_format = "12"; }
		Utility.gtk_combobox_set_value(cmbTimeFormat,1,time_format);
		
		//network
		string net = conf.network_device;
		if (net == ""){
			txtNetworkDevice.sensitive = false;
			btnWiFi.sensitive = false;
			btnLAN.sensitive = false;
			lblWidgetNetworkNotFound.label = "<i>Ø " + _("Network interface cannot be changed for selected widget") + "</i>";
			txtNetworkDevice.text = "";
		}
		else{
			txtNetworkDevice.sensitive = true;
			btnWiFi.sensitive = true;
			btnLAN.sensitive = true;
			lblWidgetNetworkNotFound.label = "";
			txtNetworkDevice.text = net.strip();
		}

		debug("-----------------------------------------------------");
	}
	
	private void btnApplyChanges_clicked () {
		set_busy(true, this);

		TreeIter iter;
		ConkyConfig conf;
		
		cmbWidget.get_active_iter(out iter);
		(cmbWidget.model).get(iter, 1, out conf);
		
		conf.stop_conky();
		
		conf.read_file();
		
		debug("-----------------------------------------------------");
		debug(_("Updating theme") + ": %s".printf(conf.Theme.Name + " - " + conf.Name));

		//location
		conf.alignment = Utility.gtk_combobox_get_value(cmbAlignment,1,"top_left");
		conf.gap_x = spinGapX.value.to_string();
		conf.gap_y = spinGapY.value.to_string();
		
		//transparency
		switch (Utility.gtk_combobox_get_value(cmbTransparencyType,1,"semi")){
			case "opaque":
				conf.own_window_transparent = "no";
				conf.own_window_argb_visual = "no";
				break;
			case "trans":
				conf.own_window_transparent = "yes";
				conf.own_window_argb_visual = "yes";
				conf.own_window_argb_value = "0";
				break;
			case "pseudo":
				conf.own_window_transparent = "yes";
				conf.own_window_argb_visual = "no";
				break;
			case "semi":
			default:
				conf.own_window_transparent = "no";
				conf.own_window_argb_visual = "yes";
				conf.own_window_argb_value = "%.0f".printf((spinOpacity.value / 100.0) * 255.0);
				break;
		}

		conf.own_window_colour = Utility.rgba_to_hex(cbtnBackgroundColor.rgba, false, false); 
		
		//window size 
		conf.minimum_size = spinMinWidth.value.to_string() + " " + spinMinHeight.value.to_string();
		conf.height_padding = (int) spinHeightPadding.value;
		
		//time
		if(conf.time_format != ""){
			conf.time_format = Utility.gtk_combobox_get_value(cmbTimeFormat,1,"");
		}
		
		//network
		if(conf.network_device != ""){
			conf.network_device = txtNetworkDevice.text;
		}
		
		//save changes to file
		conf.write_changes_to_file();
		
		debug("-----------------------------------------------------");
		
		conf.start_conky();
		
		set_busy(false, this);
	}
	
	private void btnDiscardChanges_clicked () {
		reload_widget_properties();
	}
	
	private void set_editing_options_enabled (bool enable){
		tabWidgetProperties.sensitive = enable;
		btnApplyChanges.sensitive = enable;
		btnDiscardChanges.sensitive = enable;
	}

	private void cmbTransparencyType_changed(){
		switch (Utility.gtk_combobox_get_value(cmbTransparencyType,1,"semi")){
			case "semi":
				spinOpacity.sensitive = true;
				break;
			default:
				spinOpacity.sensitive = false;
				break;
		}
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
	
	private void btnInstallThemePack_clicked ()
	{
		var dlgAddFiles = new Gtk.FileChooserDialog(_("Import Theme Pack") + " (*.cmtp.7z)", this, Gtk.FileChooserAction.OPEN,
							Gtk.Stock.CANCEL, Gtk.ResponseType.CANCEL,
							Gtk.Stock.OPEN, Gtk.ResponseType.ACCEPT);
		dlgAddFiles.local_only = true;
 		dlgAddFiles.set_modal (true);
 		dlgAddFiles.set_select_multiple (true);
 		
		Gtk.FileFilter filter = new Gtk.FileFilter ();
		dlgAddFiles.set_filter (filter);
		filter.add_pattern ("*.cmtp.7z");
		
		//show the dialog and get list of files
		
		SList<string> files = null;
 		if (dlgAddFiles.run() == Gtk.ResponseType.ACCEPT){
			files = dlgAddFiles.get_filenames();
	 	}

		//install theme packs
		
		set_busy(true, dlgAddFiles);

		int count = 0;
		if (files != null){
	 		foreach (string file in files){
				if (file.has_suffix(".cmtp.7z")){
					count += App.install_theme_pack(file);
				}
			}
		}
		
		//refresh theme list
		
	 	App.reload_themes();
	 	load_themes();
	 	dlgAddFiles.destroy ();
	 	
	 	//show message
	 	
	 	if (files != null){
			Utility.messagebox_show(_("Themes Imported"), count.to_string() + " " + _("new themes were imported."));
		}
	}
}
