IRB.conf[:HISTORY_FILE] ||= File.join(ENV["XDG_STATE_HOME"], "irb_history")
IRB.conf[:SAVE_HISTORY] = 10_000
