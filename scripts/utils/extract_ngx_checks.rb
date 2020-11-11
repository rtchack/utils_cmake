#
# Created by xing
#

NGX_FEATURE_INC_PATTERN = /ngx_feature_incs=(?<exist>"(?<content>.+))?\s*$/
NGX_FEATURE_TEST_PATTERN = /ngx_feature_test="(.+)\s*$/
NGX_FEATURE_PATTERN_MORE = /\s+(.+)\s*$/ 

# Extract Nginx checks from configuration
def extract_ngx_checks(root)
  checks = []
  confs = ['cc/conf', 'os/linux', 'unix']

  confs.each do |conf|
    file_name = File.join root, 'ngx', 'auto', conf
    puts "Parse file: #{file_name}"

    check_name = nil
    incs = nil
    incs_partial = ''
    test = nil
    test_partial = ''

    File.read(file_name).each_line do |l|
      next if l =~ /^#/

      new_check_name = l[/ngx_feature_name="(\w+)"\s*$/, 1]
      if new_check_name
        check_name = new_check_name
        incs = nil
        incs_partial = ''
        test = nil
        test_partial = ''
      end
      next unless check_name

      unless incs
        if incs_partial.empty?
          matcher = l.match NGX_FEATURE_INC_PATTERN
          next unless matcher

          if matcher[:exist]
            incs_partial = matcher[:content].strip
            next if incs_partial.empty?
            incs = incs_partial[0..-2] if incs_partial[-1] == '"'
          else
            incs = ''
          end

          next
        end

        content = l[NGX_FEATURE_PATTERN_MORE, 1]
        next unless content
        content.strip!
        next if content.empty?

        incs_partial += "\n"
        incs_partial += content
        incs = incs_partial[0..-2] if content[-1] == '"'
        next
      end

      unless test
        content = l[test_partial.empty? ?
                    NGX_FEATURE_TEST_PATTERN :
                    NGX_FEATURE_PATTERN_MORE, 1]
        next unless content
        content.strip!
        next if content.empty?

        content.gsub! '\"', '"'

        test_partial += content
        test = test_partial[0..-2] if content[-1] == '"'
        test_partial += "\n"
        next
      end

      if incs =~ /NGX_INCLUDE/
        incs.gsub! /\$NGX_INCLUDE_(\w+)_H/, '#include<\1.h>'
        incs.gsub! /_/, '/'
        incs.downcase!
      end

      target_tc = File.join(root,
                            'cmake',
                            'try_compile',
                            "#{check_name[/^NGX_?(\w+)/, 1]}.c")
      File.open(target_tc, 'w') do |f|
        puts "Generating file #{target_tc}"
        f.puts "/*\n * Created by Meissa project team in 2020\n*/"
        f.puts "\n#include <sys/types.h>\n#include <unistd.h>\n"
        f.puts incs if incs
        f.puts "\nint\nmain()\n{"
        f.print test
        f.puts "#{test[-1] == ';' ? '' : ';'}\nreturn 0;}"
      end

      yield target_tc

      checks << check_name
      check_name = nil
      incs = nil
      incs_partial = ''
      test = nil
      test_partial = ''
    end
  end

  puts "Checks:\n#{checks}"
end
