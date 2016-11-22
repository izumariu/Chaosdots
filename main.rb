#!/usr/bin/ruby
load 'ncgems.rb' # load all necessary gems

if !(/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM).nil?
  dismiss_dialog = Gtk::Dialog.new(:title=>"WHOOPSIE!!!11!!1")
  dismiss_dialog.child << Gtk::Label.new("Well, this app does not work on Windows.\nGet shit done, dude.")
  dismiss_dialog.add_button("I promise I will install Linux",0)
  dismiss_dialog.signal_connect("response") {Gtk.main_quit}
  dismiss_dialog.show_all
  Gtk.main
  exit(0)
end

builder_file = Dir.pwd << "/interface.ui"
builder = Gtk::Builder.new(:file=>builder_file)
win = builder.get_object("window1")
win.signal_connect("destroy") {Gtk.main_quit}
fc = builder.get_object("filechoose")
filter = Gtk::FileFilter.new
filter_arr = %w[png jpg gif bmp tif tiff]
filter_arr.each{|p|filter.add_pattern("*."<<p)}
fc.filter = filter
cb_gif_checked = false
send_button = builder.get_object("send_button")
cb = builder.get_object("check_ani")
fd_spin = builder.get_object("frame_delay")
fd_spin.set_range(100,3000)
fd_spin.numeric = true
fd_spin.set_increments(50.0,100.0)
fd_spin.value = 300.0
fd_spin.sensitive = false

send_button_enabled = false

def sys_fatal(title,msg,buttons)
  dismiss_dialog = Gtk::Dialog.new(:title=>title)
  dismiss_dialog.child << Gtk::Label.new(msg)
  buttons.each_with_index {|t,i|
    dismiss_dialog.add_button(t,i)
  }
  dismiss_dialog.signal_connect("response") {dismiss_dialog.destroy}
  dismiss_dialog.show_all
end

fd_spin.signal_connect("value-changed") {
  if fd_spin.value%50!=0
    until fd_spin.value%50==0
      fd_spin.value-=1
    end
  end
}

validate_all = lambda{
  send_button_enabled = true
  send_button_enabled &= fc.uri!=nil
  send_button.sensitive = send_button_enabled
}

fc.signal_connect("selection-changed") {
  cb_gif_checked = cb.active?
  if fc.uri.to_s.split("/")[-1].split(".")[-1]=='gif' # check if the file is a gif
    cb.sensitive = true
    cb.active = cb_gif_checked
  else
    cb.sensitive = false
    cb.active = false
  end
  validate_all.call
}

cb.signal_connect("toggled") {
  fd_spin.sensitive = cb.active?
}

execstr = <<EOC
convert $1 -resize 144x120 -gravity center -background black -extent 144x120 -rotate 90 -negate output.pbm &&
pnminvert output.pbm > output.inv.pbm &&
tail -n +3 output.inv.pbm > output.bin &&
dd if=output.bin skip=0 bs=720 count=1 2>/dev/null | nc -u -w 1 2001:67c:20a1:1095:ba27:ebff:feb9:db12 2323 &
dd if=output.bin skip=1 bs=720 count=1 2>/dev/null | nc -u -w 1 2001:67c:20a1:1095:ba27:ebff:fe23:60d7 2323 &
dd if=output.bin skip=2 bs=720 count=1 2>/dev/null | nc -u -w 1 2001:67c:20a1:1095:ba27:ebff:fe71:dd32 2323 &
EOC

send_button.signal_connect("clicked") {
  Dir.chdir("picedit/")
  if !cb.active?
    # single picture
    fname = fc.uri.to_s.split("file://")[-1]
    puts "MODE: single picture"
    ec = (Open3.capture3(execstr.gsub("$1",fname)) rescue nil)

    if ec[1]!=""||ec==nil
      sys_fatal(
          "Oops...",
          "There was an error converting/sending the picture.\nPlease don't punish me.\nI'm sorry.",
          ["I won't punish you"]
      )
    else
      system("rm output.*")
    end

  else

    # multiple pictures
    #TODO Prepare the sending of an animated image
    puts "MODE: multiple pictures"
    sys_fatal(
        "Oops...",
        "You can't send animated pictures yet.\nI'm sorry.",
        ["I won't punish you"]
    )

  end
  Dir.chdir("..")
}

!Dir.exist?(Dir.pwd<<"/picedit")&&Dir.mkdir(Dir.pwd<<"/picedit")

send_button.sensitive = false

Gtk.main