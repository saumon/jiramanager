module Tools
  module_function

  # For terminal coloration...
  def black(str) = "\e[30m#{str}\e[0m"
  def red(str) = "\e[31m#{str}\e[0m"
  def green(str) = "\e[32m#{str}\e[0m"
  def brown(str) = "\e[33m#{str}\e[0m"
  def blue(str) = "\e[34m#{str}\e[0m"
  def magenta(str) = "\e[35m#{str}\e[0m"
  def cyan(str) = "\e[36m#{str}\e[0m"
  def gray(str) = "\e[37m#{str}\e[0m"

  def bg_black(str) = "\e[40m#{str}\e[0m"
  def bg_red(str) = "\e[41m#{str}\e[0m"
  def bg_green(str) = "\e[42m#{str}\e[0m"
  def bg_brown(str) = "\e[43m#{str}\e[0m"
  def bg_blue(str) = "\e[44m#{str}\e[0m"
  def bg_magenta(str) = "\e[45m#{str}\e[0m"
  def bg_cyan(str) = "\e[46m#{str}\e[0m"
  def bg_gray(str) = "\e[47m#{str}\e[0m"

  def bold(str) = "\e[1m#{str}\e[22m"
  def italic(str) = "\e[3m#{str}\e[23m"
  def underline(str) = "\e[4m#{str}\e[24m"
  def blink(str) = "\e[5m#{str}\e[25m"
  def reverse_color(str) = "\e[7m#{str}\e[27m"

  def no_colors(str) = str.gsub(/\e\[\d+m/, '')

  def select_item_from_array(array_titles, question)
    if array_titles.length == 1
      puts("\n#{question} --> '#{array_titles[0]}'")
      return 0
    end

    response = 0
    loop do
      i = 0
      puts("\n#{question}")
      array_titles.each do |title|
        puts "  🍆 #{i}) #{title}"
        i += 1
      end
      print("\nIt's time to choose: ")
      response = gets.chomp.downcase
      break if /\d/ =~ response && response.to_i >= 0 && response.to_i < array_titles.length
    end
    puts ''

    response.to_i
  end

  def response_yes?(question, force: false)
    print brown("#{question} (y/n) ")
    if force
      puts 'y'
      true
    else
      gets.chomp.downcase == 'y'
    end
  end

  def pause
    print('Press any key... ')
    gets.chomp
  end

  def puts_byebye
    puts ''
    puts brown('                __ ')
    puts brown(' _             |  |')
    puts brown('| |_ _ _ ___   |  |')
    puts brown('| . | | | -_|  |__|')
    puts brown('|___|_  |___|  |__|')
    puts brown('    |___|          ')
  end

  def puts_error
    puts ''
    puts red('EEEEEEEEEEEEEEEEEEEEEE                                                                              !!! ')
    puts red('E::::::::::::::::::::E                                                                             !!:!!')
    puts red('E::::::::::::::::::::E                                                                             !:::!')
    puts red('EE::::::EEEEEEEEE::::E                                                                             !:::!')
    puts red('  E:::::E       EEEEEErrrrr   rrrrrrrrr   rrrrr   rrrrrrrrr      ooooooooooo   rrrrr   rrrrrrrrr   !:::!')
    puts red('  E:::::E             r::::rrr:::::::::r  r::::rrr:::::::::r   oo:::::::::::oo r::::rrr:::::::::r  !:::!')
    puts red('  E::::::EEEEEEEEEE   r:::::::::::::::::r r:::::::::::::::::r o:::::::::::::::or:::::::::::::::::r !:::!')
    puts red('  E:::::::::::::::E   rr::::::rrrrr::::::rrr::::::rrrrr::::::ro:::::ooooo:::::orr::::::rrrrr::::::r!:::!')
    puts red('  E:::::::::::::::E    r:::::r     r:::::r r:::::r     r:::::ro::::o     o::::o r:::::r     r:::::r!:::!')
    puts red('  E::::::EEEEEEEEEE    r:::::r     rrrrrrr r:::::r     rrrrrrro::::o     o::::o r:::::r     rrrrrrr!:::!')
    puts red('  E:::::E              r:::::r             r:::::r            o::::o     o::::o r:::::r            !!:!!')
    puts red('  E:::::E       EEEEEE r:::::r             r:::::r            o::::o     o::::o r:::::r             !!! ')
    puts red('EE::::::EEEEEEEE:::::E r:::::r             r:::::r            o:::::ooooo:::::o r:::::r                 ')
    puts red('E::::::::::::::::::::E r:::::r             r:::::r            o:::::::::::::::o r:::::r             !!! ')
    puts red('E::::::::::::::::::::E r:::::r             r:::::r             oo:::::::::::oo  r:::::r            !!:!!')
    puts red('EEEEEEEEEEEEEEEEEEEEEE rrrrrrr             rrrrrrr               ooooooooooo    rrrrrrr             !!! ')
  end

  def show_wait_spinner(fps = 10, carriage_ret: true)
    # chars = %w[| / - \\]
    chars = ['⢿', '⣻', '⣽', '⣾', '⣷', '⣯', '⣟', '⡿']
    delay = 1.0 / fps
    iter = 0
    spinner = Thread.new do
      while iter  # Keep spinning until told otherwise
        print bold cyan chars[(iter += 1) % chars.length]
        print ' '
        sleep delay
        print "\b\b"
      end
    end
    yield.tap do
      iter = false
      spinner.join
      print green '✔'
      print "\n" if carriage_ret
    end
  end
end
