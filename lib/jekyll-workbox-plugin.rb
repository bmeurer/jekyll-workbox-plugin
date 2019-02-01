class WorkboxHelper
    WORKBOX_VERSION = '3.6.3'

    def initialize(site, config)
        @site = site
        @config = config
        @sw_filename = @config['sw_dest_filename'] || 'sw.js'
        @sw_src_filepath = @config['sw_src_filepath'] || 'sw.js'
    end

    def generate_workbox_precache()
        directory = @config['precache_glob_directory'] || '/'
        directory = @site.in_dest_dir(directory)
        patterns = @config['precache_glob_patterns'] || ['**/*.{html,js,css,eot,svg,ttf,woff}']
        ignores = @config['precache_glob_ignores'] || []
        recent_posts_num = @config['precache_recent_posts_num']

        # according to workbox precache {url: 'main.js', revision: 'xxxx'}
        @precache_list = []

        # find precache files with glob
        precache_files = []
        patterns.each do |pattern|
            name_to_aliases = {}

            # this means there's no alias defined - just use file as only alias
            if pattern.is_a?(String)
                name_to_aliases = { pattern => pattern }
            elsif pattern.is_a?(Hash)
                name_to_aliases = pattern
            end

            # at this point, name_to_aliases is file -> alias or 
            # file -> [alias1, alias2], etc. there will never be more
            # than one key per yaml conventions
            filename, aliases = name_to_aliases.first

            # glob the filename, and push all aliases as just values
            Dir.glob(File.join(directory, filename)) do |filepath|
                if aliases.is_a?(String)
                    file_alias = File.join(directory, aliases)
                    precache_files.push({ filepath => file_alias })
                elsif aliases.is_a?(Array)
                    aliases.each do |filepath_alias|
                        file_alias = File.join(directory, filepath_alias)
                        precache_files.push({ filepath => file_alias })
                    end
                end
            end
        end
        precache_files = precache_files.uniq

        # precache recent n posts
        posts_path_url_map = {}
        if recent_posts_num
            precache_files.concat(
                @site.posts.docs
                    .reverse.take(recent_posts_num)
                    .map do |post|
                        posts_path_url_map[post.path] = post.url
                        { post.path => post.path }
                    end
            )
        end

        # filter with ignores
        ignores.each do |pattern|
            Dir.glob(File.join(directory, pattern)) do |ignored_filepath|
                precache_files = precache_files.select { |file_map|
                    file_map.first.first != ignored_filepath
                }.map{ |file_map| file_map }
            end
        end

        # generate md5 for each precache file
        md5 = Digest::MD5.new
        precache_files.each do |filepath_map|
            filepath, filepath_alias = filepath_map.first
            md5.reset
            md5 << File.read(filepath)
            if posts_path_url_map[filepath]
                url = posts_path_url_map[filepath]
            else
                url = filepath_alias.sub(@site.dest, '')
            end
            @precache_list.push({
                url: @site.baseurl.to_s + url,
                revision: md5.hexdigest
            })
        end
    end

    def write_sw()
        # read the sw.js source file
        sw_js_str = File.read(@site.in_source_dir(@sw_src_filepath))

        # prepend the import scripts
        sw_js_str = "importScripts('https://storage.googleapis.com/workbox-cdn/releases/#{WorkboxHelper::WORKBOX_VERSION}/workbox-sw.js');\n#{sw_js_str}"

        # generate precache list and inject it into the sw.js
        precache_list_str = @precache_list.map do |precache_item|
            precache_item.to_json
        end.join(",")
        sw_js_str = sw_js_str.sub(
            "workbox.precaching.precacheAndRoute([])",
            "workbox.precaching.precacheAndRoute([#{precache_list_str}])")

        # write sw.js
        sw_dest_file = File.new(@site.in_dest_dir(@sw_filename), 'w')
        sw_dest_file.puts(sw_js_str)
        sw_dest_file.close
    end
end

module Jekyll
    Hooks.register :site, :post_write do |site|
        pwa_config = site.config['workbox'] || {}
        sw_helper = WorkboxHelper.new(site, pwa_config)

        sw_helper.generate_workbox_precache()
        sw_helper.write_sw()
    end
end