# TW5 SERVER
# Allows editing and saving of TiddlyWiki in a browser.
#
# USAGE
# Download TiddlyWiki from https://tiddlywiki.com/empty.html and
# save it in its own subfolder as an .html file but NOT index.html.
#
# Have Ruby, and webrick ruby gem installed.
# https://www.ruby-lang.org/en/documentation/installation/
# https://rubygems.org/gems/webrick/
# 
# From the command line (e.g. Terminal on Mac):
# /usr/bin/wget https://tiddlywiki.com/empty.html -P folder/
# /usr/bin/ruby tw5-server.rb folder/empty.html
#
# Originally from:
# https://gist.github.com/jimfoltz/ee791c1bdd30ce137bc23cce826096da
# https://github.com/brianemery/tw5_server

require 'webrick'
require 'fileutils'

if ARGV.length != 0
   root = ARGV.first.gsub('\\', '/')
else
   root = '.'
end
BACKUP_DIR = 'bak'

module WEBrick
   module HTTPServlet

      class FileHandler
         alias do_PUT do_GET
      end

      class DefaultFileHandler
         def do_PUT(req, res)
            file = "#{@config[:DocumentRoot]}#{req.path}".sub(/[\/]$/,'')
            res.body = ''
            unless Dir.exist? BACKUP_DIR
               Dir.mkdir BACKUP_DIR
            end
            FileUtils.cp(file, "#{BACKUP_DIR}/#{File.basename(file, '.html')}.#{Time.now.to_i.to_s}.html")
            File.open(file, "w+") {|f| f.puts(req.body)}
         end

         def do_OPTIONS(req, res)
            res['allow'] = "GET,HEAD,POST,OPTIONS,CONNECT,PUT,DAV,dav"
            res['x-api-access-type'] = 'file'
            res['dav'] = 'tw5/put'
         end

      end
   end
end

BIND_ADDRESS = "127.0.0.1" # localhost
PORT = 8000

server = WEBrick::HTTPServer.new({:Port => PORT, :DocumentRoot => root, :BindAddress => BIND_ADDRESS})

trap "INT" do
   puts "Shutting down..."
   server.shutdown
end

puts "Serving on http://#{BIND_ADDRESS}:#{PORT}"
server.start
