#
# Created by xing
#

def compile_pb(in_dir, out_dir, languages)
  languages.each do |lang|
    case lang
    when 'cc'
      ex "protoc -I=#{in_dir} --cpp_out=#{out_dir} #{in_dir}/*.proto"
    when 'c'
      ex "protoc-c -I=#{in_dir} --c_out=#{out_dir} #{in_dir}/*.proto"
    else
      raise 'Unsupported language ${lang}, only support c/cc for now.'
    end
  end
end
