if ENV['RAILS_ENV'] == 'production'
  if !(system 'echo "hello" | text2wave | lame - - >/dev/null 2>&1')
    raise "Missing 'lame' or festival 'text2wave' command!  (on Ubuntu run the following command as root: 'apt-get install lame festival festvox-italp16k festvox-rablpc16k')"
  elsif !(system 'echo "ciao" | text2wave -eval "(language_italian)" >/dev/null 2>&1')
    raise "Missing italian festvox! (on Ubuntu run the following command as root: 'apt-get install festival festvox-italp16k festvox-rablpc16k')"
  end
end
