/*
 * GeneratePreviewWindow.vala
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

public class GeneratePreviewWindow : Dialog {
	private Button btn_ok;
	private Button btn_cancel;
	public string action = "";
	public RadioButton optGenerateCurrent;
	public RadioButton optGenerateMissing;
	public RadioButton optGenerateAll;
	private Switch switch_capture_bg;
	private Switch switch_png;
	
	public GeneratePreviewWindow() {
		title = _("Generate Preview");
        window_position = WindowPosition.CENTER_ON_PARENT;
		set_destroy_with_parent (true);
		set_modal (true);
        skip_taskbar_hint = false;
        set_default_size (350, 300);	
		icon = get_app_icon(16);
		
	    Box vbox_main = get_content_area();
		vbox_main.margin = 6;
		vbox_main.spacing = 6;
		
		Label lbl_header = new Gtk.Label("<b>" + _("Generate preview images for") + ":</b>");
		lbl_header.set_use_markup(true);
		lbl_header.xalign = (float) 0.0;
		lbl_header.margin_bottom = 6;
		vbox_main.add(lbl_header);
		
		optGenerateCurrent = new RadioButton.with_label (null, _("Selected Widget"));
		vbox_main.add(optGenerateCurrent);
		
		optGenerateMissing = new RadioButton.with_label_from_widget (optGenerateCurrent, _("All Widgets with Missing Previews"));
		vbox_main.add(optGenerateMissing);

		optGenerateAll = new RadioButton.with_label_from_widget (optGenerateCurrent, _("All Widgets (Overwrite Existing Image)"));
		vbox_main.add(optGenerateAll);

		Label lbl_header2 = new Gtk.Label("<b>" + _("Options") + ":</b>");
		lbl_header2.set_use_markup(true);
		lbl_header2.xalign = (float) 0.0;
		lbl_header2.margin_bottom = 6;
		lbl_header2.margin_top = 12;
		vbox_main.add(lbl_header2);
		
		//capture background
		Box hbox_capture_bg = new Box (Gtk.Orientation.HORIZONTAL, 6);
        vbox_main.add (hbox_capture_bg);
        
		Label lbl_capture_bg = new Gtk.Label(_("Capture Desktop Background") );
		lbl_capture_bg.hexpand = true;
		lbl_capture_bg.xalign = (float) 0.0;
		lbl_capture_bg.valign = Align.CENTER;
		lbl_capture_bg.set_tooltip_text(_("When enabled, the generated image will have the same background as the current desktop wallpaper. When disabled, the background will be a solid color (the widget's background color)."));
		hbox_capture_bg.add(lbl_capture_bg);

        switch_capture_bg = new Gtk.Switch();
        switch_capture_bg.set_size_request(100,20);
        switch_capture_bg.active =  App.capture_background;
        hbox_capture_bg.pack_end(switch_capture_bg,false,false,0);
		
		switch_capture_bg.notify["active"].connect(()=>{
			App.capture_background = switch_capture_bg.active;
		});
		
		
		//png images
		Box hbox_png = new Box (Gtk.Orientation.HORIZONTAL, 6);
        vbox_main.add (hbox_png);
        
		Label lbl_png = new Gtk.Label(_("High quality images (PNG)") );
		lbl_png.hexpand = true;
		lbl_png.xalign = (float) 0.0;
		lbl_png.valign = Align.CENTER;
		lbl_png.set_tooltip_text(_("Generate preview images in PNG format instead of JPEG"));
		hbox_png.add(lbl_png);

        switch_png = new Gtk.Switch();
        switch_png.set_size_request(100,20);
        switch_png.active =  App.generate_png;
        hbox_png.pack_end(switch_png,false,false,0);
		
		switch_png.notify["active"].connect(()=>{
			App.generate_png = switch_png.active;
		});
		
		//hbox_commands --------------------------------------------------
		
		Box hbox_action = (Box) get_action_area();
		
		//btn_ok
		btn_ok = new Button.with_label("  " + _("OK"));
		btn_ok.set_image(new Image.from_stock ("gtk-ok", IconSize.MENU));
		
        btn_ok.clicked.connect(()=>{ 
			if (optGenerateCurrent.active){
				action = "current";
			}
			else if (optGenerateMissing.active){
				action = "missing";
			}
			else if (optGenerateAll.active){
				action = "all";
			}
			else {
				action = "";
			}
			
			this.response(Gtk.ResponseType.OK); 
			});
			
		hbox_action.add(btn_ok);
		
		//btn_cancel
		btn_cancel = new Button.with_label("  " + _("Cancel"));
		btn_cancel.set_image (new Image.from_stock ("gtk-cancel", IconSize.MENU));
        btn_cancel.clicked.connect(()=>{ this.response(Gtk.ResponseType.CANCEL); });
		hbox_action.add(btn_cancel);
	}
}
