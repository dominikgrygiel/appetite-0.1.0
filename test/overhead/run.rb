require 'tempfile'

wd = File.expand_path('..', __FILE__) << '/'
port = 60080
rps = nil

if app_pid = Process.spawn("ruby #{wd}app.rb #{port} &> /dev/null")
  puts 'running test, please wait ...'
  sleep 2
  cmd = "ab -n1000 -c100 -q localhost:#{port}/|grep 'Requests per second'"
  file = ::Tempfile.new(app_pid.to_s)
  bench_pid = Process.spawn(cmd, :out => file.path)
  Process.wait(bench_pid)
  Process.kill 9, app_pid
  file.rewind
  rps = file.read.sub('Requests per second', '').strip.sub(/.*\:\s+(.*)\s+\[.*/, '\1').to_i
end

rps || exit(1)

# app regular speed
ars = lambda do |overhead, ms|
  out = (1000 / (overhead + ms)).to_i.to_s
  (" " * ((6 + ms.to_s.size) - out.size)) << out << "  "
end

overhead = 1000.to_f / rps.to_f

puts "---"
puts "Requests per second  Overhead  1ms-app  5ms-app  10ms-app  20ms-app  50ms-app  100ms-app"
puts "%s%s  %sms    %s%s%s%s%s%s" % [
    " "*(19-rps.to_s.size),
    rps,
    '%.2f' % overhead,
    ars.call(overhead, 1),
    ars.call(overhead, 5),
    ars.call(overhead, 10),
    ars.call(overhead, 20),
    ars.call(overhead, 50),
    ars.call(overhead, 100),
]
puts "---"
