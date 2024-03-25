
using Gtk;
using Gst;

namespace Recorder {

    public class MainWindow : Adw.ApplicationWindow {

private Stack stack;
private Box vbox_list_page;
private Box vbox_rename_page;
private dynamic Element player;
private ListBox list_box;
private Adw.EntryRow entry_name;
private SearchEntry entry_search;
private Button back_button;
private Button delete_button;
private Button edit_button;
private Button search_button;
private Button play_button;
private Button stop_button;
private Button record_button;
private Button stop_record_button;
private Label current_action;
private Entry entry_time;
private MP3Recorder mp3_recorder;
private Bus bus;
private Adw.ToastOverlay overlay;
private Adw.Window window_timer;
private string directory_path;
private string item;
private uint timeout_id = 0;
Gst.Bus player_bus;

        public MainWindow(Adw.Application application) {
            GLib.Object(application: application,
                         title: "Recorder",
                         resizable: true,
                         default_height: 500);
            mp3_recorder = MP3Recorder.get_default ();
            player = ElementFactory.make ("playbin", "player");
            bus = new Bus (player);
            player_bus = player.get_bus ();
            player_bus.add_signal_watch ();
            player_bus.message.connect (bus.parse_message);
        }

        construct {
        back_button = new Button();
            back_button.set_icon_name ("go-previous-symbolic");
            back_button.vexpand = false;
        delete_button = new Button();
            delete_button.set_icon_name ("list-remove-symbolic");
            delete_button.vexpand = false;
        edit_button = new Button();
            edit_button.set_icon_name ("document-edit-symbolic");
            edit_button.vexpand = false;
        search_button = new Button();
            search_button.set_icon_name("edit-find-symbolic");
            search_button.vexpand = false;
        play_button = new Button();
            play_button.set_icon_name ("media-playback-start-symbolic");
            play_button.vexpand = false;
        stop_button = new Button();
            stop_button.set_icon_name ("media-playback-stop-symbolic");
            stop_button.vexpand = false;
        record_button = new Button();
            record_button.set_icon_name ("media-record-symbolic");
            record_button.vexpand = false;
        stop_record_button = new Button();
            stop_record_button.set_icon_name ("process-stop-symbolic");
            stop_record_button.vexpand = false;
        var menu_button = new Gtk.MenuButton();
            menu_button.set_icon_name ("open-menu-symbolic");
            menu_button.vexpand = false;
        back_button.set_tooltip_text(_("Back"));
        delete_button.set_tooltip_text(_("Delete file"));
        edit_button.set_tooltip_text(_("Rename file"));
        search_button.set_tooltip_text(_("Search"));
        play_button.set_tooltip_text(_("Play"));
        stop_button.set_tooltip_text(_("Stop"));
        record_button.set_tooltip_text(_("Start recording"));
        stop_record_button.set_tooltip_text(_("Stop recording"));
        back_button.clicked.connect(on_back_clicked);
        delete_button.clicked.connect(on_delete_dialog);
        edit_button.clicked.connect(on_edit_clicked);
        search_button.clicked.connect(()=>{
               if(entry_search.is_visible()){
                  entry_search.hide();
                  entry_search.set_text("");
                  if(item != null){
                     list_box.select_row(list_box.get_row_at_index(get_index(item)));
                  }
               }else{
                  entry_search.show();
                  entry_search.grab_focus();
               }
            });
        record_button.clicked.connect(on_record_clicked);
        stop_record_button.clicked.connect(on_stop_record_clicked);
        play_button.clicked.connect(on_play_clicked);
        stop_button.clicked.connect(on_stop_clicked);
        var headerbar = new Adw.HeaderBar();
        headerbar.add_css_class("flat");
        headerbar.pack_start(back_button);
        headerbar.pack_start(delete_button);
        headerbar.pack_start(edit_button);
        headerbar.pack_start(search_button);
        headerbar.pack_end(menu_button);
        headerbar.pack_end(stop_button);
        headerbar.pack_end(play_button);
        headerbar.pack_end(record_button);
        headerbar.pack_end(stop_record_button);
        var timer_action = new GLib.SimpleAction ("timer", null);
        timer_action.activate.connect (on_timer_dialog);
        var open_directory_action = new GLib.SimpleAction ("open", null);
        open_directory_action.activate.connect (on_open_directory_clicked);
        var about_action = new GLib.SimpleAction ("about", null);
        about_action.activate.connect (about);
        var quit_action = new GLib.SimpleAction ("quit", null);
        var app = GLib.Application.get_default();
        quit_action.activate.connect(()=>{
               app.quit();
            });
        app.add_action(timer_action);
        app.add_action(open_directory_action);
        app.add_action(about_action);
        app.add_action(quit_action);
        var menu = new GLib.Menu();
        var item_timer = new GLib.MenuItem (_("Timer"), "app.timer");
        var item_open = new GLib.MenuItem (_("Open the Records folder"), "app.open");
        var item_about = new GLib.MenuItem (_("About Recorder"), "app.about");
        var item_quit = new GLib.MenuItem (_("Quit"), "app.quit");
        menu.append_item (item_timer);
        menu.append_item (item_open);
        menu.append_item (item_about);
        menu.append_item (item_quit);
        var popover = new PopoverMenu.from_model(menu);
        menu_button.set_popover(popover);
        set_widget_visible(back_button,false);
        set_widget_visible(stop_record_button, false);
        set_widget_visible(stop_button,false);
          stack = new Stack();
          stack.set_transition_duration (600);
          stack.set_transition_type (StackTransitionType.SLIDE_LEFT_RIGHT);
          stack.set_margin_end(10);
          stack.set_margin_top(10);
          stack.set_margin_start(10);
          stack.set_margin_bottom(10);
          overlay = new Adw.ToastOverlay();
          overlay.set_child(stack);
          var main_box = new Box(Orientation.VERTICAL, 0);
          main_box.append(headerbar);
          main_box.append(overlay);
          set_content(main_box);
        list_box = new Gtk.ListBox ();
        list_box.vexpand = true;
        list_box.add_css_class("boxed-list");
        list_box.row_selected.connect(on_select_item);
        var scroll = new Gtk.ScrolledWindow () {
            propagate_natural_height = true,
            propagate_natural_width = true
        };
        var clamp = new Adw.Clamp(){
            tightening_threshold = 100,
            margin_top = 5,
            margin_bottom = 5
        };
        clamp.set_child(list_box);

        scroll.set_child(clamp);
	
	entry_search = new SearchEntry();
        entry_search.hexpand = true;
        entry_search.changed.connect(show_files);
        entry_search.margin_start = 35;
        entry_search.margin_end = 35;
        entry_search.hide();

        current_action = new Label(_("Welcome!"));
        current_action.add_css_class("title-4");
	current_action.wrap = true;
        current_action.wrap_mode = WORD;
   vbox_list_page = new Box(Orientation.VERTICAL,5);
   vbox_list_page.append (entry_search);
   vbox_list_page.append (current_action);
   vbox_list_page.append (scroll);
   stack.add_child(vbox_list_page);
    var clear_name = new Button();
        clear_name.set_icon_name("edit-clear-symbolic");
        clear_name.add_css_class("destructive-action");
        clear_name.add_css_class("circular");
        clear_name.valign = Align.CENTER;
        entry_name = new Adw.EntryRow();
        entry_name.add_suffix(clear_name);
        entry_name.set_title(_("Name"));
        entry_name.changed.connect((event) => {
            on_entry_change(entry_name, clear_name);
        });
        clear_name.clicked.connect((event) => {
            on_clear_entry(entry_name);
        });
        var list = new ListBox();
        list.add_css_class("boxed-list");
        list.append(entry_name);
         var button_ok = new Button.with_label(_("OK"));
        button_ok.add_css_class("suggested-action");
        button_ok.clicked.connect(on_ok_clicked);
        vbox_rename_page = new Box(Orientation.VERTICAL,10);
        vbox_rename_page.margin_start = 20;
        vbox_rename_page.margin_end = 20;
        vbox_rename_page.append(list);
        vbox_rename_page.append(button_ok);
        stack.add_child(vbox_rename_page);
        stack.visible_child = vbox_list_page;
   directory_path = Environment.get_user_data_dir()+"/Recordings";
   GLib.File file = GLib.File.new_for_path(directory_path);
   if(!file.query_exists()){
     try{
        file.make_directory();
     }catch(Error e){
        stderr.printf ("Error: %s\n", e.message);
     }
   }
   show_files();
 }
private void on_clear_entry(Adw.EntryRow entry){
    entry.set_text("");
    entry.grab_focus();
}
private void on_entry_change(Adw.EntryRow entry, Gtk.Button clear){
    if (!is_empty(entry.get_text())) {
        clear.set_visible(true);
    } else {
        clear.set_visible(false);
    }
}
 private void on_play_clicked(){
    var selection = list_box.get_selected_row();
           if (!selection.is_selected()) {
               set_toast(_("Please choose a file"));
               return;
           }
 player.uri = "file://"+directory_path+"/"+item;
 player.set_state (State.PLAYING);
 current_action.set_text(_("Now playing: ")+item);
 set_widget_visible(play_button,false);
 set_widget_visible(stop_button,true);
}

private void on_stop_clicked(){
 player.set_state (State.NULL);
 current_action.set_text(_("Playback stopped"));
 set_widget_visible(play_button,true);
 set_widget_visible(stop_button,false);
}

private void on_record_clicked(){
try {
   mp3_recorder.start_recording();
 } catch (Gst.ParseError e) {
    alert("",e.message);
    return;
 }
 if(mp3_recorder.is_recording){
     current_action.set_text(_("Recording is in progress"));
 }else{
     alert(_("Error!\nFailed to start recording"),"");
     return;
 }
 show_files();
 list_box.select_row(list_box.get_row_at_index(get_index(mp3_recorder.filename + ".mp3")));
 set_widget_visible(record_button,false);
 set_widget_visible(stop_record_button,true);
}

private void on_stop_record_clicked(){
   mp3_recorder.stop_recording();
   current_action.set_text(_("Recording stopped"));
   set_widget_visible(record_button,true);
   set_widget_visible(stop_record_button,false);
   remove_timeout();
}
   private void on_open_directory_clicked(){
      Gtk.show_uri(this, "file://"+directory_path, Gdk.CURRENT_TIME);
  }

   private void on_select_item () {
             var selection = list_box.get_selected_row();
           if (!selection.is_selected()) {
               return;
           }
          GLib.Value value = "";
          selection.get_property("title", ref value);
          item = value.get_string();
       }

   private void on_edit_clicked(){
        var selection = list_box.get_selected_row();
           if (!selection.is_selected()) {
               set_toast(_("Choose a file"));
               return;
           }
        stack.visible_child = vbox_rename_page;
        set_buttons_on_rename_page();
        entry_name.set_text(item);
   }

   private void on_ok_clicked(){
         if(is_empty(entry_name.get_text())){
		    set_toast(_("Enter the name"));
                    entry_name.grab_focus();
                    return;
		}
		GLib.File select_file = GLib.File.new_for_path(directory_path+"/"+item);
		GLib.File edit_file = GLib.File.new_for_path(directory_path+"/"+entry_name.get_text().replace("&", "and").strip());
		if (select_file.get_basename() != edit_file.get_basename() && !edit_file.query_exists()){
                FileUtils.rename(select_file.get_path(), edit_file.get_path());
                if(!edit_file.query_exists()){
                    set_toast(_("Rename failed"));
                    return;
                }
            }else{
                if(select_file.get_basename() != edit_file.get_basename()){
                    alert(_("A file with the same name already exists"),"");
                    entry_name.grab_focus();
                    return;
                }
            }
      show_files();
      list_box.select_row(list_box.get_row_at_index(get_index(edit_file.get_basename())));
      on_back_clicked();
   }

   private void on_back_clicked(){
       stack.visible_child = vbox_list_page;
       set_buttons_on_list_page();
   }

   private void on_delete_dialog(){
    var selection = list_box.get_selected_row();
    if (!selection.is_selected()) {
        set_toast(_("Choose a file"));
        return;
    }
           GLib.File file = GLib.File.new_for_path(directory_path+"/"+item);
        var delete_file_dialog = new Adw.MessageDialog(this, _("Delete file %s?").printf(file.get_basename()), "");
            delete_file_dialog.add_response("cancel", _("_Cancel"));
            delete_file_dialog.add_response("ok", _("_Delete"));
            delete_file_dialog.set_default_response("ok");
            delete_file_dialog.set_close_response("cancel");
            delete_file_dialog.set_response_appearance("ok", DESTRUCTIVE);
            delete_file_dialog.show();
            delete_file_dialog.response.connect((response) => {
                if (response == "ok") {
                    FileUtils.remove (directory_path+"/"+item);
                    if(file.query_exists()){
                       set_toast(_("Delete failed"));
                    }else{
                       show_files();
                    }
                }
                delete_file_dialog.close();
            });
         }

   private void on_timer_dialog(){
        window_timer = new Adw.Window();
        window_timer.set_title (_("Timer"));
        window_timer.set_transient_for (this);
        window_timer.set_modal (true);
        entry_time = new Gtk.Entry();
        var label_time = new Gtk.Label.with_mnemonic (_("_End of recording in (minutes):"));
        label_time.set_halign (Gtk.Align.START);
        var vbox = new Gtk.Box (Gtk.Orientation.VERTICAL, 5);
        vbox.append (label_time);
        vbox.append (entry_time);
        var start_timer_button = new Gtk.Button.with_label (_("Start timer"));
        start_timer_button.clicked.connect(on_start_timer);
        var close_button = new Gtk.Button.with_label (_("Close"));
        close_button.clicked.connect(()=>{
           window_timer.close();
        });
		var hbox = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 5);
        hbox.set_halign (Gtk.Align.END);
        hbox.append (close_button);
        hbox.append (start_timer_button);

        var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 10);
        box.vexpand = true;
        box.append (vbox);
        box.append (hbox);

        var clamp = new Adw.Clamp ();
        clamp.valign = Gtk.Align.CENTER;
        clamp.tightening_threshold = 100;
        clamp.margin_top = 10;
        clamp.margin_bottom = 20;
        clamp.margin_start = 20;
        clamp.margin_end = 20;
        clamp.set_child (box);

        var headerbar = new Adw.HeaderBar();
        headerbar.add_css_class("flat");

        var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        main_box.append (headerbar);
        main_box.append (clamp);

        window_timer.set_content (main_box);
        window_timer.show();
    }

   private void on_start_timer(){
        if(!mp3_recorder.is_recording){
            set_toast(_("Recording not started!"));
            return;
        }

        if(is_empty(entry_time.get_text())){
            set_toast(_("Enter time in minutes"));
            entry_time.grab_focus();
            return;
        }

        if(timeout_id != 0){
            var cancel_timer_dialog = new Adw.MessageDialog(this, _("The timer has already been started earlier and has not yet completed its work"), "");
            cancel_timer_dialog.add_response("cancel", _("_Close"));
            cancel_timer_dialog.add_response("ok", _("_Cancel the timer"));
            cancel_timer_dialog.set_default_response("ok");
            cancel_timer_dialog.set_close_response("cancel");
            cancel_timer_dialog.set_response_appearance("ok", SUGGESTED);
            cancel_timer_dialog.show();
            cancel_timer_dialog.response.connect((response) => {
                if (response == "ok") {
                    remove_timeout();
                }
                cancel_timer_dialog.close();
            });
            return;
        }

        int time = int.parse(entry_time.get_text())*60;

        timeout_id = Timeout.add_seconds(time, () => {
            on_stop_record_clicked();
            return false;
        });

        set_toast(_("The timer is running"));

        window_timer.close();
    }

   private void show_files () {
        var list = new GLib.List<string> ();
            try {
            Dir dir = Dir.open (directory_path, 0);
            string? name = null;
            while ((name = dir.read_name ()) != null) {
                 if(entry_search.is_visible()){
                    if(name.down().contains(entry_search.get_text().down())){
                       list.append(name);
                    }
                    }else{
                       list.append(name);
                }
            }
        } catch (FileError err) {
            stderr.printf (err.message);
        }
        for (
            var child = (Gtk.ListBoxRow) list_box.get_last_child ();
                child != null;
                child = (Gtk.ListBoxRow) list_box.get_last_child ()
        ) {
            list_box.remove(child);
        }
           foreach (string item in list) {
                var row = new Adw.ActionRow () {
                title = item
            };
            list_box.append(row);
           }
       }

     private int get_index(string item){
            int index_of_item = 0;
            try {
            Dir dir = Dir.open (directory_path, 0);
            string? name = null;
            int index = 0;
            while ((name = dir.read_name ()) != null) {
                index++;
                if(name == item){
                  index_of_item = index - 1;
                  break;
                }
            }
        } catch (FileError err) {
            stderr.printf (err.message);
          }
          return index_of_item;
        }

   private void set_widget_visible (Gtk.Widget widget, bool visible) {
         widget.visible = !visible;
         widget.visible = visible;
  }

   private void set_buttons_on_list_page(){
       set_widget_visible(back_button,false);
       set_widget_visible(delete_button,true);
       set_widget_visible(edit_button,true);
       set_widget_visible(search_button,true);
   }

   private void set_buttons_on_rename_page(){
       set_widget_visible(back_button,true);
       set_widget_visible(delete_button,false);
       set_widget_visible(edit_button,false);
       set_widget_visible(search_button,false);
   }

   private bool is_empty(string str){
        return str.strip().length == 0;
      }

   private void remove_timeout () {
        if (timeout_id != 0) {
            GLib.Source.remove (timeout_id);
            timeout_id = 0;
        }
    }

     private void about () {
	        var win = new Adw.AboutWindow () {
                application_name = "Recorder",
                application_icon = "com.github.alexkdeveloper.recorder",
                version = "1.0.17",
                copyright = "Copyright © 2022-2024 Alex Kryuchkov",
                license_type = License.GPL_3_0,
                developer_name = "Alex Kryuchkov",
                developers = {"Alex Kryuchkov https://github.com/alexkdeveloper"},
                translator_credits = _("translator-credits"),
                website = "https://github.com/alexkdeveloper/recorder",
                issue_url = "https://github.com/alexkdeveloper/recorder/issues"
            };
            win.set_transient_for (this);
            win.show ();
        }

   private void set_toast (string str){
       var toast = new Adw.Toast(str);
       toast.set_timeout(3);
       overlay.add_toast(toast);
   }

   private void alert (string heading, string body){
            var dialog_alert = new Adw.MessageDialog(this, heading, body);
            if (body != "") {
                dialog_alert.set_body(body);
            }
            dialog_alert.add_response("ok", _("_OK"));
            dialog_alert.set_response_appearance("ok", SUGGESTED);
            dialog_alert.response.connect((_) => { dialog_alert.close(); });
            dialog_alert.show();
        }
   }
}
