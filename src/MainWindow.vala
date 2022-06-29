
using Gtk;
using Gst;

namespace Recorder {

    public class MainWindow : Adw.ApplicationWindow {

private Stack stack;
private Box vbox_list_page;
private Box vbox_rename_page;
private dynamic Element player;
private Gtk.ListStore list_store;
private TreeView tree_view;
private GLib.List<string> list;
private Entry entry_name;
private Button back_button;
private Button delete_button;
private Button edit_button;
private Button play_button;
private Button stop_button;
private Button record_button;
private Button stop_record_button;
private Label current_action;
private MP3Recorder mp3_recorder;
private Bus bus;
private Adw.ToastOverlay overlay;
private string directory_path;
private string item;
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
        back_button = new Button ();
            back_button.set_icon_name ("go-previous-symbolic");
            back_button.vexpand = false;
        delete_button = new Button ();
            delete_button.set_icon_name ("list-remove-symbolic");
            delete_button.vexpand = false;
        edit_button = new Button ();
            edit_button.set_icon_name ("document-edit-symbolic");
            edit_button.vexpand = false;
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
        var open_directory_button = new Button();
            open_directory_button.set_icon_name ("folder-open-symbolic");
            open_directory_button.vexpand = false;
        back_button.set_tooltip_text(_("Back"));
        delete_button.set_tooltip_text(_("Delete file"));
        edit_button.set_tooltip_text(_("Rename file"));
        play_button.set_tooltip_text(_("Play"));
        stop_button.set_tooltip_text(_("Stop"));
        record_button.set_tooltip_text(_("Start recording"));
        stop_record_button.set_tooltip_text(_("Stop recording"));
        open_directory_button.set_tooltip_text(_("Open the Records folder"));
        back_button.clicked.connect(on_back_clicked);
        delete_button.clicked.connect(on_delete_dialog);
        edit_button.clicked.connect(on_edit_clicked);
        record_button.clicked.connect(on_record_clicked);
        stop_record_button.clicked.connect(on_stop_record_clicked);
        open_directory_button.clicked.connect(on_open_directory_clicked);
        play_button.clicked.connect(on_play_clicked);
        stop_button.clicked.connect(on_stop_clicked);
        var headerbar = new Adw.HeaderBar();
        headerbar.pack_start(back_button);
        headerbar.pack_start(delete_button);
        headerbar.pack_start(edit_button);
        headerbar.pack_end(stop_button);
        headerbar.pack_end(play_button);
        headerbar.pack_end(open_directory_button);
        headerbar.pack_end(record_button);
        headerbar.pack_end(stop_record_button);
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
   list_store = new Gtk.ListStore(Columns.N_COLUMNS, typeof(string));
           tree_view = new TreeView.with_model(list_store);
           var text = new CellRendererText ();
           var column = new TreeViewColumn ();
           column.pack_start (text, true);
           column.add_attribute (text, "markup", Columns.TEXT);
           tree_view.append_column (column);
           tree_view.set_headers_visible (false);
           tree_view.cursor_changed.connect(on_select_item);
   var scroll = new ScrolledWindow ();
        scroll.set_policy (PolicyType.AUTOMATIC, PolicyType.AUTOMATIC);
        scroll.set_vexpand(true);
        scroll.set_child (this.tree_view);
        current_action = new Label(_("Welcome!"));
	current_action.wrap = true;
        current_action.wrap_mode = WORD;
   vbox_list_page = new Box(Orientation.VERTICAL,10);
   vbox_list_page.append (current_action);
   vbox_list_page.append (scroll);
   stack.add_child(vbox_list_page);
        entry_name = new Entry();
        entry_name.set_icon_from_icon_name (Gtk.EntryIconPosition.SECONDARY, "edit-clear-symbolic");
        entry_name.icon_press.connect ((pos, event) => {
              entry_name.set_text("");
              entry_name.grab_focus();
        });
        var label_name = new Label.with_mnemonic (_("_Name:"));
        label_name.set_xalign(0);
        var vbox_name = new Box (Orientation.VERTICAL, 5);
        vbox_name.append (label_name);
        vbox_name.append (entry_name);
        var button_ok = new Button.with_label("OK");
        button_ok.clicked.connect(on_ok_clicked);
        vbox_rename_page = new Box(Orientation.VERTICAL,10);
        vbox_rename_page.append(vbox_name);
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

 private void on_play_clicked(){
    var selection = tree_view.get_selection();
      selection.set_mode(SelectionMode.SINGLE);
      TreeModel model;
      TreeIter iter;
      if (!selection.get_selected(out model, out iter)) {
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
    alert(e.message);
    return;
 }
 if(mp3_recorder.is_recording){
     current_action.set_text(_("Recording is in progress"));
 }else{
     alert(_("Error!\nFailed to start recording"));
     return;
 }
 show_files();
 set_widget_visible(record_button,false);
 set_widget_visible(stop_record_button,true);
}

private void on_stop_record_clicked(){
   mp3_recorder.stop_recording();
   current_action.set_text(_("Recording stopped"));
   set_widget_visible(record_button,true);
   set_widget_visible(stop_record_button,false);

}
   private void on_open_directory_clicked(){
      Gtk.show_uri(this, "file://"+directory_path, Gdk.CURRENT_TIME);
  }

   private void on_select_item () {
           var selection = tree_view.get_selection();
           selection.set_mode(SelectionMode.SINGLE);
           TreeModel model;
           TreeIter iter;
           if (!selection.get_selected(out model, out iter)) {
               return;
           }
           TreePath path = model.get_path(iter);
           var index = int.parse(path.to_string());
           if (index >= 0) {
               item = list.nth_data(index);
           }
       }

   private void on_edit_clicked(){
         var selection = tree_view.get_selection();
           selection.set_mode(SelectionMode.SINGLE);
           TreeModel model;
           TreeIter iter;
           if (!selection.get_selected(out model, out iter)) {
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
		GLib.File edit_file = GLib.File.new_for_path(directory_path+"/"+entry_name.get_text().strip());
		if (select_file.get_basename() != edit_file.get_basename() && !edit_file.query_exists()){
                FileUtils.rename(select_file.get_path(), edit_file.get_path());
                if(!edit_file.query_exists()){
                    set_toast(_("Rename failed"));
                    return;
                }
            }else{
                if(select_file.get_basename() != edit_file.get_basename()){
                    alert(_("A file with the same name already exists"));
                    entry_name.grab_focus();
                    return;
                }
            }
      show_files();
      on_back_clicked();
   }

   private void on_back_clicked(){
       stack.visible_child = vbox_list_page;
       set_buttons_on_list_page();
   }

   private void on_delete_dialog(){
       var selection = tree_view.get_selection();
           selection.set_mode(SelectionMode.SINGLE);
           TreeModel model;
           TreeIter iter;
           if (!selection.get_selected(out model, out iter)) {
               set_toast(_("Choose a file"));
               return;
           }
           GLib.File file = GLib.File.new_for_path(directory_path+"/"+item);
         var delete_file_dialog = new Gtk.MessageDialog(this, Gtk.DialogFlags.MODAL,Gtk.MessageType.QUESTION, Gtk.ButtonsType.OK_CANCEL, _("Delete file ")+file.get_basename()+"?");
         delete_file_dialog.set_title(_("Question"));
         delete_file_dialog.show ();
         delete_file_dialog.response.connect((response) => {
                if (response == Gtk.ResponseType.OK) {
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

   private void show_files () {
           list_store.clear();
           list = new GLib.List<string> ();
            try {
            Dir dir = Dir.open (directory_path, 0);
            string? name = null;
            while ((name = dir.read_name ()) != null) {
                list.append(name);
            }
        } catch (FileError err) {
            stderr.printf (err.message);
        }
         TreeIter iter;
           foreach (string item in list) {
               list_store.append(out iter);
               list_store.set(iter, Columns.TEXT, item);
           }
       }

   private void set_widget_visible (Gtk.Widget widget, bool visible) {
         widget.visible = !visible;
         widget.visible = visible;
  }

   private void set_buttons_on_list_page(){
       set_widget_visible(back_button,false);
       set_widget_visible(delete_button,true);
       set_widget_visible(edit_button,true);
   }

   private void set_buttons_on_rename_page(){
       set_widget_visible(back_button,true);
       set_widget_visible(delete_button,false);
       set_widget_visible(edit_button,false);
   }

   private bool is_empty(string str){
        return str.strip().length == 0;
      }

       private enum Columns {
           TEXT, N_COLUMNS
       }

   private void set_toast (string str){
       var toast = new Adw.Toast(str);
       toast.set_timeout(3);
       overlay.add_toast(toast);
   }

   private void alert (string str){
          var dialog_alert = new Gtk.MessageDialog(this, Gtk.DialogFlags.MODAL, Gtk.MessageType.INFO, Gtk.ButtonsType.OK, str);
          dialog_alert.set_title(_("Message"));
          dialog_alert.response.connect((_) => { dialog_alert.close(); });
          dialog_alert.show();
       }
   }
}
