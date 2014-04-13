/*
 * EditWindow.vala
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
	private Notebook tab_main;
	private Notebook tab_widget_properties;
	private Box hbox_commands;
	
	private Label lbl_theme_tab;
	private Box vbox_theme;
	private Box hbox_theme_buttons;

	private Label lbl_options_tab;
	private Box vbox_options;

	private Label lbl_edit_tab;

	private Label lbl_about_tab;
	private Box vbox_about;

	private Label lbl_app_name;
	private Label lbl_app_version;
	private Label lbl_author;
	private LinkButton lnk_blog;
	
	private Label lbl_header_startup;
	private CheckButton chkStartup;
	private Box hbox_install_theme_pack;
	private Label lbl_header_theme_dir;
	private FileChooserButton fcb_theme_dir;
	private Label lbl_header_theme_pack;
	private Button btn_install_theme_pack;
	
	private Label lbl_header_widget;
	private Label lbl_background_color;
	private Label lbl_alignment;
	private Label lbl_gap_x;
	private Label lbl_gap_y;
	private Label lbl_transparency;
	private Label lbl_min_width;
	private Label lbl_min_height;
	private Label lbl_widget_time_not_found;
	private Label lbl_widget_network_not_found;
	private ComboBox cmb_alignment;
	private ComboBox cmb_widget;
	private ComboBox cmb_transparency_type;
	private ComboBox cmb_time_format;
	private SpinButton spin_gap_x;
	private SpinButton spin_gap_y;
	private SpinButton spin_opacity;
	private SpinButton spin_min_width;
	private SpinButton spin_min_height;
	private SpinButton spin_height_padding;
	private ColorButton cbtn_bg_color;
	private Entry txt_network_device;
	private Button btn_wifi;
	private Button btn_lan;
	private Button btn_show_desktop;
	
	private TreeView tv_theme;
	private ScrolledWindow sw_theme;
	private TreeViewColumn col_theme_name;
	private TreeViewColumn col_theme_enabled;
	
	private TreeView tv_config;
	private ScrolledWindow sw_config;
	private TreeViewColumn col_widget_name;
	private TreeViewColumn col_widget_enabled;
	
	private Button btn_theme_info;
	private Button btn_theme_preview;
	private Button btn_reload_themes;
	private Button btn_apply_changes;
	private Button btn_discard_changes;

	private Label lbl_header_kill_conky;
	private Button btn_kill_conky;

	public MainWindow() {
		this.title = AppName + " v" + AppVersion + " by " + AppAuthor + " (" + "teejeetech.blogspot.in" + ")";
        this.window_position = WindowPosition.CENTER;
        this.destroy.connect (Gtk.main_quit);
        set_default_size (400, 20);	

		//set app icon
		try{
			this.icon = new Gdk.Pixbuf.from_file ("""/usr/share/pixmaps/conky-manager.png""");
		}
        catch(Error e){
	        log_error (e.message);
	    }
	    
		//tab_main
        tab_main = new Notebook ();
		tab_main.margin = 6;
		tab_main.switch_page.connect(tab_main_switch_page);
		add(tab_main);
		
		//vbox_theme
        vbox_theme = new Box (Orientation.VERTICAL, 6);
		vbox_theme.margin = 6;

        //lbl_theme_tab
		lbl_theme_tab = new Label (_("Theme"));

		tab_main.append_page (vbox_theme, lbl_theme_tab);

		//tv_theme
		tv_theme = new TreeView();
		tv_theme.get_selection().mode = SelectionMode.SINGLE;
		tv_theme.get_selection().changed.connect(tv_theme_selection_changed);
		tv_theme.set_tooltip_text ("");
		tv_theme.set_rules_hint (true);
		//tv_theme.headers_visible = false;
		
		sw_theme = new ScrolledWindow(tv_theme.get_hadjustment (), tv_theme.get_vadjustment ());
		sw_theme.set_shadow_type (ShadowType.ETCHED_IN);
		sw_theme.add (tv_theme);
		sw_theme.set_size_request (-1, 250);
		vbox_theme.pack_start (sw_theme, true, true, 0);
		
		//Theme Name Column
		col_theme_name = new TreeViewColumn();
		col_theme_name.title = _("Theme");
		col_theme_name.resizable = true;
		col_theme_name.expand = true;
		
		CellRendererText cell_theme_name = new CellRendererText ();
		cell_theme_name.ellipsize = Pango.EllipsizeMode.END;
		cell_theme_name.width = 200;
		col_theme_name.pack_start (cell_theme_name, false);
		col_theme_name.set_cell_data_func (cell_theme_name, tv_theme_cell_theme_name_render);
		tv_theme.append_column(col_theme_name);
		
		//'Enabled' Column
		col_theme_enabled = new TreeViewColumn();
		col_theme_enabled.title = _("Enable");
		col_theme_enabled.resizable = false;
		//col_theme_enabled.sizing = TreeViewColumnSizing.AUTOSIZE; 
		col_theme_enabled.expand = false;
		
		CellRendererToggle cell_theme_enabled = new CellRendererToggle ();
		cell_theme_enabled.radio = false;
		cell_theme_enabled.activatable = true;
		cell_theme_enabled.width = 50;
		cell_theme_enabled.toggled.connect (tv_theme_cell_theme_enabled_toggled);
		col_theme_enabled.pack_start (cell_theme_enabled, false);
		col_theme_enabled.set_cell_data_func (cell_theme_enabled, tv_theme_cell_theme_enabled_render);
		tv_theme.append_column(col_theme_enabled);
		
		//tv_config
		tv_config = new TreeView();
		tv_config.get_selection().mode = SelectionMode.MULTIPLE;
		tv_config.set_rules_hint (true);
		//tv_config.headers_visible = false;
		
		sw_config = new ScrolledWindow(tv_config.get_hadjustment (), tv_config.get_vadjustment ());
		sw_config.set_shadow_type (ShadowType.ETCHED_IN);
		sw_config.add (tv_config);
		sw_config.set_size_request (-1, 180);
		vbox_theme.pack_start (sw_config, false, true, 0);
		
		//Theme Name Column
		col_widget_name = new TreeViewColumn();
		col_widget_name.title = _("Widget");
		col_widget_name.resizable = true;
		col_widget_name.expand = true;
		
		CellRendererText cell_widget_name = new CellRendererText ();
		cell_widget_name.ellipsize = Pango.EllipsizeMode.END;
		cell_widget_name.width = 200;
		col_widget_name.pack_start (cell_widget_name, false);
		col_widget_name.set_cell_data_func (cell_widget_name, tv_config_cell_widget_name_render);
		tv_config.append_column(col_widget_name);
		
		//'Enabled' Column
		col_widget_enabled = new TreeViewColumn();
		col_widget_enabled.title = _("Enable");
		col_widget_enabled.resizable = false;
		col_widget_enabled.expand = false;
		
		CellRendererToggle cell_widget_enabled = new CellRendererToggle ();
		cell_widget_enabled.radio = false;
		cell_widget_enabled.activatable = true;
		cell_widget_enabled.width = 50;
		cell_widget_enabled.toggled.connect (tv_config_cell_widget_enabled_toggled);
		col_widget_enabled.pack_start (cell_widget_enabled, false);
		col_widget_enabled.set_cell_data_func (cell_widget_enabled, tv_config_cell_widget_enabled_render);
		tv_config.append_column(col_widget_enabled);
		
		//hbox_theme_buttons
		hbox_theme_buttons = new Box (Orientation.HORIZONTAL, 6); 
		hbox_theme_buttons.set_homogeneous(true);
		vbox_theme.add(hbox_theme_buttons);
		
		//btn_theme_info
		btn_theme_info = new Button.with_label(_("Info"));
		btn_theme_info.set_image (new Image.from_stock (Stock.INFO, IconSize.MENU));
        btn_theme_info.clicked.connect (btn_theme_info_clicked);
        btn_theme_info.set_tooltip_text (_("Theme Info"));
        btn_theme_info.set_sensitive(false);
		hbox_theme_buttons.add(btn_theme_info);
		
		//btn_theme_preview
		btn_theme_preview = new Button.with_label(_("Preview"));
		//btn_theme_preview.set_image (new Image.from_stock (Stock.INFO, IconSize.MENU));
        btn_theme_preview.clicked.connect (btn_theme_preview_clicked);
        btn_theme_preview.set_tooltip_text (_("Preview Theme"));
        btn_theme_preview.set_sensitive(false);
		hbox_theme_buttons.add(btn_theme_preview);

		//btn_reload_themes
		btn_reload_themes = new Button.with_label(_("Refresh List"));
		btn_reload_themes.set_image (new Image.from_stock (Stock.REFRESH, IconSize.MENU));
        btn_reload_themes.clicked.connect (() => {
			App.load_themes();
			this.load_themes();
			});
        btn_reload_themes.set_tooltip_text (_("Reload list of themes"));
		hbox_theme_buttons.add(btn_reload_themes);

        //Edit tab ---------------------------

        //lbl_edit_tab
		lbl_edit_tab = new Label (_("Edit"));

		//grid_edit
        Grid grid_edit = new Grid ();
        grid_edit.set_column_spacing (6);
        grid_edit.set_row_spacing (6);
        grid_edit.column_homogeneous = false;
        grid_edit.visible = false;
        grid_edit.margin = 12;
        tab_main.append_page (grid_edit, lbl_edit_tab);

        CellRendererText textCell;
        
        //lbl_header_widget
		lbl_header_widget = new Gtk.Label("<b>" + _("Widget") + "</b>");
		lbl_header_widget.set_use_markup(true);
		lbl_header_widget.xalign = (float) 0.0;
		lbl_header_widget.margin_bottom = 6;
		grid_edit.attach(lbl_header_widget,0,0,2,1);
		
        //cmb_widget
		cmb_widget = new ComboBox();
		textCell = new CellRendererText();
        cmb_widget.pack_start( textCell, false );
        cmb_widget.set_attributes( textCell, "text", 0 );
        cmb_widget.changed.connect(cmb_widget_changed);
        cmb_widget.margin_left = 6;
        cmb_widget.margin_right = 6;
        cmb_widget.hexpand = true;
        grid_edit.attach(cmb_widget,0,1,1,1);
		
		//btn_show_desktop
        btn_show_desktop = new Button.with_label(_("Show Desktop"));
        btn_show_desktop.clicked.connect (() => {
			//show desktop
			App.minimize_all_other_windows();
			});
		btn_show_desktop.set_size_request(100,-1);
        btn_show_desktop.set_tooltip_text (_("Minimize all windows and show the widget on the desktop"));
		grid_edit.attach(btn_show_desktop,1,1,1,1);
		
		//lbl_header_widgetProperties
		Label lbl_header_widgetProperties = new Gtk.Label("<b>" + _("Properties") + "</b>");
		lbl_header_widgetProperties.set_use_markup(true);
		lbl_header_widgetProperties.xalign = (float) 0.0;
		lbl_header_widgetProperties.margin_top = 6;
		grid_edit.attach(lbl_header_widgetProperties,0,2,2,1);
		
        //tab_widget_properties ---------------------------------------
        tab_widget_properties = new Notebook ();
		tab_widget_properties.margin = 6;
		tab_widget_properties.tab_pos = PositionType.LEFT;
		tab_widget_properties.expand = true;
		grid_edit.attach(tab_widget_properties,0,3,2,1);
		
		//lblWidgetLocation
		Label lblWidgetLocation = new Label (_("Location"));

		//grid_widget_location -----------------------------------------------
		
        Grid grid_widget_location = new Grid ();
        grid_widget_location.set_column_spacing (12);
        grid_widget_location.set_row_spacing (6);
        grid_widget_location.column_homogeneous = false;
        grid_widget_location.visible = false;
        grid_widget_location.margin = 12;
        tab_widget_properties.append_page (grid_widget_location, lblWidgetLocation);
        
		int row = -1;
		
		//lbl_alignment
		lbl_alignment = new Gtk.Label(_("Alignment"));
		lbl_alignment.margin_left = 6;
		lbl_alignment.xalign = (float) 0.0;
		grid_widget_location.attach(lbl_alignment,0,++row,1,1);
		
		//cmb_alignment
		cmb_alignment = new ComboBox();
		textCell = new CellRendererText();
        cmb_alignment.pack_start( textCell, false );
        cmb_alignment.set_attributes( textCell, "text", 0 );
        grid_widget_location.attach(cmb_alignment,1,row,1,1);
		
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
		cmb_alignment.set_model(model);
		
		//lbl_gap_x
		lbl_gap_x = new Gtk.Label(_("Horizontal Gap"));
		lbl_gap_x.set_tooltip_text("[GAP_X] Horizontal distance from window border (in pixels)");
		lbl_gap_x.margin_left = 6;
		lbl_gap_x.xalign = (float) 0.0;
		grid_widget_location.attach(lbl_gap_x,0,++row,1,1);
		
		//spin_gap_x
		spin_gap_x = new SpinButton.with_range(-10000,10000,10);
		spin_gap_x.xalign = (float) 0.5;
		spin_gap_x.value = 0.0;
		grid_widget_location.attach(spin_gap_x,1,row,1,1);
		
		//lbl_gap_y
		lbl_gap_y = new Gtk.Label(_("Vertical Gap"));
		lbl_gap_y.set_tooltip_text("[GAP_Y] Vertical distance from window border (in pixels)");
		lbl_gap_y.margin_left = 6;
		lbl_gap_y.xalign = (float) 0.0;
		grid_widget_location.attach(lbl_gap_y,0,++row,1,1);
		
		//spin_gap_y
		spin_gap_y = new SpinButton.with_range(-10000,10000,10);
		spin_gap_y.xalign = (float) 0.5;
		spin_gap_y.value = 0.0;
		spin_gap_y.set_size_request(120,-1);
		grid_widget_location.attach(spin_gap_y,1,row,1,1);
		
		//lblWidgetTransparency
		Label lblWidgetTransparency = new Label (_("Transparency"));

		//grid_widget_transparency  -----------------------------------------------------------
		
        Grid grid_widget_transparency = new Grid ();
        grid_widget_transparency.set_column_spacing (12);
        grid_widget_transparency.set_row_spacing (6);
        grid_widget_transparency.column_homogeneous = false;
        grid_widget_transparency.visible = false;
        grid_widget_transparency.margin = 12;
        tab_widget_properties.append_page (grid_widget_transparency, lblWidgetTransparency);
        
        row = -1;
        
		string tt = "";
		
        //lblBackgroundType
		Label lblBackgroundType = new Gtk.Label(_("Transparency Type"));
		lblBackgroundType.margin_left = 6;
		lblBackgroundType.xalign = (float) 0.0;
		lblBackgroundType.set_tooltip_text(tt);
		lblBackgroundType.set_use_markup(true);
		grid_widget_transparency.attach(lblBackgroundType,0,row,1,1);
		
        //cmb_transparency_type
		cmb_transparency_type = new ComboBox();
		textCell = new CellRendererText();
        cmb_transparency_type.pack_start( textCell, false );
        cmb_transparency_type.set_attributes( textCell, "text", 0 );
        cmb_transparency_type.changed.connect(cmb_transparency_type_changed);
		cmb_transparency_type.set_tooltip_text(tt);
        grid_widget_transparency.attach(cmb_transparency_type,1,row,2,1);
		
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
		cmb_transparency_type.set_model(model);

		tt = _("Window Opacity\n\n0 = Fully Transparent, 100 = Fully Opaque");
		
		//lbl_transparency
		lbl_transparency = new Gtk.Label(_("Opacity (%)"));
		lbl_transparency.set_tooltip_text(tt);
		lbl_transparency.margin_left = 6;
		lbl_transparency.xalign = (float) 0.0;
		grid_widget_transparency.attach(lbl_transparency,0,++row,1,1);
		
		//spin_opacity
		spin_opacity = new SpinButton.with_range(0,100,10);
		spin_opacity.set_tooltip_text(tt);
		spin_opacity.xalign = (float) 0.5;
		spin_opacity.value = 100.0;
		//spin_opacity.set_size_request(120,-1);
		grid_widget_transparency.attach(spin_opacity,1,row,1,1);
		
		//lbl_background_color
		lbl_background_color = new Gtk.Label(_("Background Color"));
		lbl_background_color.margin_left = 6;
		lbl_background_color.xalign = (float) 0.0;
		grid_widget_transparency.attach(lbl_background_color,0,++row,1,1);
		
		//cbtn_bg_color
		cbtn_bg_color = new ColorButton();
		grid_widget_transparency.attach(cbtn_bg_color,1,row,1,1);
		
		//lbl_transparencyExpander
		Label lbl_transparencyExpander = new Gtk.Label("");
		lbl_transparencyExpander.margin_left = 6;
		lbl_transparencyExpander.vexpand = true;
		grid_widget_transparency.attach(lbl_transparencyExpander,0,++row,3,1);
		
		tt = "Ø " + _("Setting Type to \"Transparent\" will make the whole window transparent (including any images). Use \"Pseudo-Transparent\" if you want the images to be opaque.");
		
		//lblSize1
		Label lblTrans1 = new Gtk.Label(tt);
		lblTrans1.margin_left = 6;
		lblTrans1.margin_bottom = 6;
		lblTrans1.xalign = (float) 0.0;
		lblTrans1.set_size_request(100,-1);
		lblTrans1.set_line_wrap(true);
		grid_widget_transparency.attach(lblTrans1,0,++row,3,1);
		
		tt = "Ø " + _("Setting Type to \"Pseudo-Transparent\" will make the window transparent but the window will have a shadow. The shadow can be disabled by configuring your window manager.");
		
		//lblSize1
		Label lblTrans2 = new Gtk.Label(tt);
		lblTrans2.margin_left = 6;
		lblTrans2.margin_bottom = 6;
		lblTrans2.xalign = (float) 0.0;
		lblTrans2.set_size_request(100,-1);
		lblTrans2.set_line_wrap(true);
		grid_widget_transparency.attach(lblTrans2,0,++row,3,1);
		
		//lblWidgetSize
		Label lblWidgetSize = new Label (_("Size"));

		//grid_widget_size  -----------------------------------------------------------
		
        Grid grid_widget_size = new Grid ();
        grid_widget_size.set_column_spacing (12);
        grid_widget_size.set_row_spacing (6);
        grid_widget_size.column_homogeneous = false;
        grid_widget_size.visible = false;
        grid_widget_size.margin = 12;
        grid_widget_size.border_width = 1;
        tab_widget_properties.append_page (grid_widget_size, lblWidgetSize);
        
        row = -1;
        
        tt = _("Width should be larger than the size of window contents,\notherwise this setting will not have any effect");
		
		//lbl_min_width
		lbl_min_width = new Gtk.Label(_("Minimum Width"));
		lbl_min_width.margin_left = 6;
		lbl_min_width.xalign = (float) 0.0;
		lbl_min_width.set_tooltip_text(tt);
		grid_widget_size.attach(lbl_min_width,0,++row,1,1);
		
		//spin_min_width
		spin_min_width = new SpinButton.with_range(0,9999,10);
		spin_min_width.xalign = (float) 0.5;
		spin_min_width.value = 100.0;
		spin_min_width.set_size_request(120,-1);
		spin_min_width.set_tooltip_text(tt);
		grid_widget_size.attach(spin_min_width,1,row,1,1);
		
		tt = _("Height should be larger than the size of window contents,\notherwise this setting will not have any effect");
		
		//lbl_min_height
		lbl_min_height = new Gtk.Label(_("Minimum Height"));
		lbl_min_height.margin_left = 6;
		lbl_min_height.xalign = (float) 0.0;
		lbl_min_height.set_tooltip_text(tt);
		grid_widget_size.attach(lbl_min_height,0,++row,1,1);
		
		//spin_min_height
		spin_min_height = new SpinButton.with_range(0,9999,10);
		spin_min_height.xalign = (float) 0.5;
		spin_min_height.value = 100.0;
		spin_min_height.set_tooltip_text(tt);
		grid_widget_size.attach(spin_min_height,1,row,1,1);
		
		tt = _("Increases the window height by adding empty lines at the end of the Conky config file");
		
		//lblTrailingLines
		Label lblTrailingLines = new Gtk.Label(_("Height Padding"));
		lblTrailingLines.margin_left = 6;
		lblTrailingLines.xalign = (float) 0.0;
		lblTrailingLines.set_tooltip_text(tt);
		grid_widget_size.attach(lblTrailingLines,0,++row,1,1);
		
		//spin_height_padding
		spin_height_padding = new SpinButton.with_range(0,100,1);
		spin_height_padding.xalign = (float) 0.5;
		spin_height_padding.value = 0.0;
		spin_height_padding.set_tooltip_text(tt);
		grid_widget_size.attach(spin_height_padding,1,row,1,1);
		
		//lblSizeExpander
		Label lblSizeExpander = new Gtk.Label("");
		lblSizeExpander.margin_left = 6;
		lblSizeExpander.vexpand = true;
		grid_widget_size.attach(lblSizeExpander,0,++row,3,1);
		
		tt = "Ø " + _("The minimum width & height must be more than the size of the window contents, otherwise the setting will not have any effect.");
		
		//lblSize1
		Label lblSize1 = new Gtk.Label(tt);
		lblSize1.margin_left = 6;
		lblSize1.margin_bottom = 6;
		lblSize1.xalign = (float) 0.0;
		lblSize1.set_size_request(100,-1);
		lblSize1.set_line_wrap(true);
		grid_widget_size.attach(lblSize1,0,++row,3,1);
		
		tt = "Ø " + _("Setting Type to \"Opaque\" (from the transparency tab) will make it easier to see the changes");
		
		//lbl_size2
		Label lbl_size2 = new Gtk.Label(tt);
		lbl_size2.margin_left = 6;
		lbl_size2.margin_bottom = 6;
		lbl_size2.xalign = (float) 0.0;
		lbl_size2.set_size_request(100,-1);
		lbl_size2.set_line_wrap(true);
		grid_widget_size.attach(lbl_size2,0,++row,3,1);
		
		//lbl_widget_time
		Label lbl_widget_time = new Label (_("Time"));

		//grid_widget_time  -----------------------------------------------------------
		
        Grid grid_widget_time = new Grid ();
        grid_widget_time.set_column_spacing (12);
        grid_widget_time.set_row_spacing (6);
        grid_widget_time.column_homogeneous = false;
        grid_widget_time.visible = false;
        grid_widget_time.margin = 12;
        grid_widget_time.border_width = 1;
        tab_widget_properties.append_page (grid_widget_time, lbl_widget_time);
		
		row = -1;
		
        //lblTimeFormat
		Label lblTimeFormat = new Gtk.Label(_("Time Format"));
		lblTimeFormat.margin_left = 6;
		lblTimeFormat.xalign = (float) 0.0;
		lblTimeFormat.set_use_markup(true);
		grid_widget_time.attach(lblTimeFormat,0,++row,1,1);
		
        //cmb_time_format
		cmb_time_format = new ComboBox();
		textCell = new CellRendererText();
        cmb_time_format.pack_start( textCell, false );
        cmb_time_format.set_attributes( textCell, "text", 0 );
        grid_widget_time.attach(cmb_time_format,1,row,1,1);
		
		//lbl_widget_time_not_found
		lbl_widget_time_not_found = new Gtk.Label("");
		lbl_widget_time_not_found.set_use_markup(true);
		lbl_widget_time_not_found.xalign = (float) 0.0;
		lbl_widget_time_not_found.margin = 6;
		grid_widget_time.attach(lbl_widget_time_not_found,0,++row,2,1);
		
		//populate
		model = new Gtk.ListStore (2, typeof (string), typeof (string));
		model.append (out iter);
		model.set (iter,0,_("12 Hour"),1,"12");
		model.append (out iter);
		model.set (iter,0,_("24 Hour"),1,"24");
		cmb_time_format.set_model(model);
		
		//lblWidgetNetwork
		Label lblWidgetNetwork = new Label (_("Network"));

		//grid_widget_network  -----------------------------------------------------------
		
        Grid grid_widget_network = new Grid ();
        grid_widget_network.set_column_spacing (12);
        grid_widget_network.set_row_spacing (6);
        grid_widget_network.column_homogeneous = false;
        grid_widget_network.visible = false;
        grid_widget_network.margin = 12;
        grid_widget_network.border_width = 1;
        tab_widget_properties.append_page (grid_widget_network, lblWidgetNetwork);
		
		row = -1;

        //lblNetworkDevice
		Label lblNetworkDevice = new Gtk.Label(_("Interface"));
		lblNetworkDevice.margin_left = 6;
		lblNetworkDevice.xalign = (float) 0.0;
		lblNetworkDevice.set_use_markup(true);
		grid_widget_network.attach(lblNetworkDevice,0,++row,1,1);
		
		//txt_network_device
        txt_network_device =  new Gtk.Entry();
        grid_widget_network.attach(txt_network_device,1,row,1,1);
        
        //btn_wifi
        btn_wifi = new Button.with_label(_("WiFi"));
        btn_wifi.clicked.connect (() => {
			txt_network_device.text = "wlan0";
			});
		btn_wifi.set_size_request(50,-1);
        btn_wifi.set_tooltip_text (_("WiFi Network") + " (wlan0)");
		grid_widget_network.attach(btn_wifi,2,row,1,1);
		
        //btn_lan
        btn_lan = new Button.with_label(_("LAN"));
        btn_lan.clicked.connect (() => {
			txt_network_device.text = "eth0";
			});
		btn_lan.set_size_request(50,-1);
        btn_lan.set_tooltip_text (_("Wired LAN Network") + " (eth0)");
		grid_widget_network.attach(btn_lan,3,row,1,1);

		//lbl_widget_network_not_found
		lbl_widget_network_not_found = new Gtk.Label("");
		lbl_widget_network_not_found.set_use_markup(true);
		lbl_widget_network_not_found.xalign = (float) 0.0;
		lbl_widget_network_not_found.margin = 6;
		grid_widget_network.attach(lbl_widget_network_not_found,0,++row,4,1);
		
		//hbox_commands --------------------------------------------------
		
        Box hbox_edit_buttons = new Box (Orientation.HORIZONTAL, 6);
        hbox_edit_buttons.homogeneous = true;
        grid_edit.attach(hbox_edit_buttons,0,5,2,1);
        
		//btn_apply_changes
		btn_apply_changes = new Button.with_label("  " + _("Apply Changes"));
		btn_apply_changes.set_image (new Image.from_stock (Stock.APPLY, IconSize.MENU));
        btn_apply_changes.clicked.connect (btn_apply_changes_clicked);
        btn_apply_changes.set_tooltip_text (_("Apply Changes"));
        btn_apply_changes.set_size_request(-1,30);
		hbox_edit_buttons.add(btn_apply_changes);
		
		//btn_discard_changes
		btn_discard_changes = new Button.with_label("  " + _("Discard"));
		btn_discard_changes.set_image (new Image.from_stock (Stock.CANCEL, IconSize.MENU));
        btn_discard_changes.clicked.connect (btn_discard_changes_clicked);
        btn_discard_changes.set_tooltip_text (_("Apply Changes"));
        btn_discard_changes.set_size_request(-1,30);
		hbox_edit_buttons.add(btn_discard_changes);
		
		//Options tab ---------------------------
		
		//vbox_options
        vbox_options = new Box (Orientation.VERTICAL, 6);
		vbox_options.margin = 12;

        //lbl_options_tab
		lbl_options_tab = new Label (_("Options"));

		tab_main.append_page (vbox_options, lbl_options_tab);

		
		
		//About tab ---------------------------
		
		//vbox_about
        vbox_about = new Box (Orientation.VERTICAL, 6);
		vbox_about.margin = 12;

        //lbl_about_tab
		lbl_about_tab = new Label (_("About"));

		tab_main.append_page (vbox_about, lbl_about_tab);
		
        //lbl_app_name
		lbl_app_name = new Gtk.Label("""<span size="x-large" weight="bold">""" + AppName + "</span>");
		lbl_app_name.set_use_markup(true);
		lbl_app_name.xalign = (float) 0.0;
		lbl_app_name.margin_top = 0;
		lbl_app_name.margin_bottom = 6;
		vbox_about.add(lbl_app_name);
		
		lbl_app_version = new Gtk.Label(_("Version") + ": " + AppVersion);
		lbl_app_version.set_use_markup(true);
		lbl_app_version.xalign = (float) 0.0;
		vbox_about.add(lbl_app_version);
		
		lbl_author = new Gtk.Label("(c) 2013, " + AppAuthor + " (" + AppAuthorEmail + ")");
		lbl_author.set_use_markup(true);
		lbl_author.xalign = (float) 0.0;
		vbox_about.add(lbl_author);
		
		lnk_blog = new Gtk.LinkButton("http://teejeetech.blogspot.in");
		lnk_blog.xalign = (float) 0.0;
		lnk_blog.uri = "http://teejeetech.blogspot.in";
		vbox_about.add(lnk_blog);
		
		lnk_blog.activate_link.connect(() => { 
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
		if (tv_theme.get_selection().get_selected(out model, out iter)){
			model.get (iter, 0, out th, -1); //get theme
			name = th.Name;
		}

		//populate tv_theme
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
		tv_theme.model = store;
		
		//re-select theme
		if(found){
			tv_theme.get_selection().select_iter(selected_iter);
		}

		//populate cmb_widget
		store = new Gtk.ListStore (2, typeof (string), typeof (ConkyConfig));
		foreach(ConkyTheme theme in App.ThemeList) {
			foreach(ConkyConfig conf in theme.ConfigList) {
				store.append(out iter);
				store.set(iter, 0, theme.Name + " - " + conf.Name, 1, conf);
			}
		}
		cmb_widget.set_model(store);
		cmb_widget.set_active (-1);
		set_editing_options_enabled(false);
		
		//store = new ListStore(1,typeof(ConkyConfig));
		//tv_config.model = store;
	}
	
	//tab_main handlers ---------------------------
	
	private void tab_main_switch_page (Widget page, uint new_page) {
		uint old_page = tab_main.page;
		
		if ((cmb_widget == null) || (cmb_widget.model == null)){
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
			
			if (cmb_widget.active != -1){
				//kill all widgets
				App.kill_all_conky();

				//restart saved widgets
				App.run_startup_script();
				
				cmb_widget.set_active (-1);
			}
		
			set_busy(false, this);
		}
	}
	
	//Edit tab handlers ----------

	private void cmb_widget_changed () {
		TreeIter iter;
		ConkyConfig conf;
		
		if (cmb_widget.active == -1){
			set_editing_options_enabled(false);
			return;
		}
		else{
			set_editing_options_enabled(true);
		}

		cmb_widget.get_active_iter(out iter);
		(cmb_widget.model).get(iter, 1, out conf);

		reload_widget_properties();
		
		if (tab_main.page == 1){
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

		if (cmb_widget.active == -1){
			set_editing_options_enabled(false);
			return;
		}
		else{
			set_editing_options_enabled(true);
		}
		
		cmb_widget.get_active_iter(out iter);
		(cmb_widget.model).get(iter, 1, out conf);
		
		debug("-----------------------------------------------------");
		debug(_("Load theme") + ": %s".printf(conf.Theme.Name + " - " + conf.Name));

		conf.read_file();
		
		//location
		gtk_combobox_set_value(cmb_alignment, 1, conf.alignment);
		spin_gap_x.value = double.parse(conf.gap_x);
		spin_gap_y.value = double.parse(conf.gap_y);
		
		string own_window_transparent = conf.own_window_transparent;
		string own_window_argb_visual = conf.own_window_argb_visual;
		string own_window_argb_value = conf.own_window_argb_value;
		
		//transparency
		if(own_window_transparent == "yes"){
			if(own_window_argb_visual == "yes"){
				//own_window_argb_value, if present, will be ignored by Conky
				gtk_combobox_set_value(cmb_transparency_type,1,"trans");
			}
			else if (own_window_argb_visual == "no"){
				gtk_combobox_set_value(cmb_transparency_type,1,"pseudo");
			}
			else{
				gtk_combobox_set_value(cmb_transparency_type,1,"pseudo");
			}
		}
		else if (own_window_transparent == "no"){
			if(own_window_argb_visual == "yes"){
				if (own_window_argb_value == "0"){
					gtk_combobox_set_value(cmb_transparency_type,1,"trans");
				}
				else if (own_window_argb_value == "255"){
					gtk_combobox_set_value(cmb_transparency_type,1,"opaque");
				}
				else{
					gtk_combobox_set_value(cmb_transparency_type,1,"semi");
				}
			}
			else if (own_window_argb_visual == "no"){
				gtk_combobox_set_value(cmb_transparency_type,1,"opaque");
			}
			else{
				gtk_combobox_set_value(cmb_transparency_type,1,"opaque");
			}
		}
		else{
			gtk_combobox_set_value(cmb_transparency_type,1,"opaque");
		}

		if (own_window_argb_value == ""){
			spin_opacity.value = 0;
		}
		else{
			spin_opacity.value = (int.parse(own_window_argb_value) / 255.0) * 100;
		}
		cbtn_bg_color.rgba = hex_to_rgba(conf.own_window_colour);
		
		//window size 
		string size = conf.minimum_size;
		spin_min_width.value = int.parse(size.split(" ")[0]);
		spin_min_height.value = int.parse(size.split(" ")[1]);
		spin_height_padding.value = conf.height_padding;
		
		//time
		string time_format = conf.time_format;
		
		if (time_format == "") {
			cmb_time_format.sensitive = false;
			lbl_widget_time_not_found.label = "<i>Ø " + _("Time format cannot be changed for selected widget") + "</i>";
		}
		else{
			cmb_time_format.sensitive = true;
			lbl_widget_time_not_found.label = "";
		}
		
		if (time_format == "") { time_format = "12"; }
		gtk_combobox_set_value(cmb_time_format,1,time_format);
		
		//network
		string net = conf.network_device;
		if (net == ""){
			txt_network_device.sensitive = false;
			btn_wifi.sensitive = false;
			btn_lan.sensitive = false;
			lbl_widget_network_not_found.label = "<i>Ø " + _("Network interface cannot be changed for selected widget") + "</i>";
			txt_network_device.text = "";
		}
		else{
			txt_network_device.sensitive = true;
			btn_wifi.sensitive = true;
			btn_lan.sensitive = true;
			lbl_widget_network_not_found.label = "";
			txt_network_device.text = net.strip();
		}

		debug("-----------------------------------------------------");
	}
	
	private void btn_apply_changes_clicked () {
		set_busy(true, this);

		TreeIter iter;
		ConkyConfig conf;
		
		cmb_widget.get_active_iter(out iter);
		(cmb_widget.model).get(iter, 1, out conf);
		
		conf.stop_conky();
		
		conf.read_file();
		
		debug("-----------------------------------------------------");
		debug(_("Updating theme") + ": %s".printf(conf.Theme.Name + " - " + conf.Name));

		//location
		conf.alignment = gtk_combobox_get_value(cmb_alignment,1,"top_left");
		conf.gap_x = spin_gap_x.value.to_string();
		conf.gap_y = spin_gap_y.value.to_string();
		
		//transparency
		switch (gtk_combobox_get_value(cmb_transparency_type,1,"semi")){
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
				conf.own_window_argb_value = "%.0f".printf((spin_opacity.value / 100.0) * 255.0);
				break;
		}

		conf.own_window_colour = rgba_to_hex(cbtn_bg_color.rgba, false, false); 
		
		//window size 
		conf.minimum_size = spin_min_width.value.to_string() + " " + spin_min_height.value.to_string();
		conf.height_padding = (int) spin_height_padding.value;
		
		//time
		if(conf.time_format != ""){
			conf.time_format = gtk_combobox_get_value(cmb_time_format,1,"");
		}
		
		//network
		if(conf.network_device != ""){
			conf.network_device = txt_network_device.text;
		}
		
		//save changes to file
		conf.write_changes_to_file();
		
		debug("-----------------------------------------------------");
		
		conf.start_conky();
		
		set_busy(false, this);
	}
	
	private void btn_discard_changes_clicked () {
		reload_widget_properties();
	}
	
	private void set_editing_options_enabled (bool enable){
		tab_widget_properties.sensitive = enable;
		btn_apply_changes.sensitive = enable;
		btn_discard_changes.sensitive = enable;
	}

	private void cmb_transparency_type_changed(){
		switch (gtk_combobox_get_value(cmb_transparency_type,1,"semi")){
			case "semi":
				spin_opacity.sensitive = true;
				break;
			default:
				spin_opacity.sensitive = false;
				break;
		}
	}
	
	//tv_theme Handlers -----------
	
	private void tv_theme_cell_theme_enabled_render (CellLayout cell_layout, CellRenderer cell, TreeModel model, TreeIter iter){
		ConkyTheme theme;
		model.get (iter, 0, out theme, -1);
		(cell as Gtk.CellRendererToggle).active = theme.Enabled;
	}
	
	private void tv_theme_cell_theme_name_render (CellLayout cell_layout, CellRenderer cell, TreeModel model, TreeIter iter){
		ConkyTheme theme;
		model.get (iter, 0, out theme, -1);
		(cell as Gtk.CellRendererText).text = theme.Name;
	}
	
	private void tv_theme_cell_theme_enabled_toggled (string path){
		set_busy(true, this);
		
		ConkyTheme theme;
		TreeIter iter;
		
		ListStore model = (ListStore) tv_theme.model; //get model
		model.get_iter_from_string (out iter, path); //get selected iter
		model.get (iter, 0, out theme, -1); //get theme
		
		theme.Enabled = !theme.Enabled;

		//refresh tv_config 
		//Thread.usleep((ulong)1000000);
		model = (ListStore) tv_config.model;
		tv_config.model = null;
		tv_config.model = model;
		
		set_busy(false, this);
	}

	private void tv_theme_selection_changed () {
		set_busy(true, this);
		
		//populate config list ----------
		
		ConkyTheme theme = null;
		TreeIter iter;
		TreeModel model;
		ListStore store;
		
		if (tv_theme.get_selection().get_selected(out model, out iter)){
			model.get (iter, 0, out theme, -1); //get theme
			
			store = new ListStore(1,typeof(ConkyConfig));
			foreach(ConkyConfig conf in theme.ConfigList){
				store.append(out iter);
				store.set(iter, 0, conf);
			}
			tv_config.model = store;
		}
		
		//set preview and info buttons ---------
		
		if (theme != null) {
			if (file_exists(theme.InfoFile)){
				btn_theme_info.set_sensitive(true);
			}
			else{
				btn_theme_info.set_sensitive(false);
			}
			
			if (file_exists(theme.PreviewImage)){
				btn_theme_preview.set_sensitive(true);
			}
			else{
				btn_theme_preview.set_sensitive(false);
			}
		}
		
		set_busy(false, this);
	}
	
	//tv_config Handlers -----------
	
	private void tv_config_cell_widget_enabled_render (CellLayout cell_layout, CellRenderer cell, TreeModel model, TreeIter iter){
		ConkyConfig conf;
		model.get (iter, 0, out conf, -1);
		(cell as Gtk.CellRendererToggle).active = conf.Enabled;
	}
	
	private void tv_config_cell_widget_name_render (CellLayout cell_layout, CellRenderer cell, TreeModel model, TreeIter iter){
		ConkyConfig conf;
		model.get (iter, 0, out conf, -1);
		(cell as Gtk.CellRendererText).text = conf.Name;
	}
	
	private void tv_config_cell_widget_enabled_toggled (string path){
		set_busy(true, this);
		
		ConkyConfig conf;
		TreeIter iter;
		
		ListStore model = (ListStore) tv_config.model; //get model
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
	
	private void set_busy (bool busy, Gtk.Window win) {
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
	
	private void do_events (){
		while(Gtk.events_pending ())
			Gtk.main_iteration ();
	}
	
	private ConkyTheme? tv_theme_get_selected_theme(){
		ConkyTheme theme = null;
		TreeIter iter;
		TreeModel model;

		if (tv_theme.get_selection().get_selected(out model, out iter)){
			model.get (iter, 0, out theme, -1); //get theme
			return theme;
		}
		
		return null;
	}

	//hbox_theme_buttons ------------------------
	
	private void btn_theme_info_clicked () {
		ConkyTheme theme = tv_theme_get_selected_theme();
		if (theme != null){
			string info = "";
			if (file_exists(theme.InfoFile)){
				info = read_file(theme.InfoFile);
			}
			
			gtk_messagebox_show("[" + _("Info") + "] " + theme.Name, info);
		}
	}
	
	private void btn_theme_preview_clicked () {
		ConkyTheme theme = tv_theme_get_selected_theme();;
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
	
	private void chk_startup_clicked (){
		App.autostart(chkStartup.active);
	}
	
	public void fcb_theme_dir_file_set(){
		string dir = fcb_theme_dir.get_filename ();

		if (!dir_exists(dir)){
			create_dir(dir);
		}
		
		if (dir_exists(dir)){
			App.data_dir = dir;
		}
		
		App.init_directories();
		App.init_theme_packs();
		App.load_themes();
		load_themes();
	}
	
	private void btn_install_theme_pack_clicked (){
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
		
	 	App.load_themes();
	 	load_themes();
	 	dlgAddFiles.destroy ();
	 	
	 	//show message
	 	
	 	if (files != null){
			gtk_messagebox_show(_("Themes Imported"), count.to_string() + " " + _("new themes were imported."));
		}
	}
}
