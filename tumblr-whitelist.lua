-- tumblr.lua
-- usage: wget --mirror --lua-script=tumblr.lua --warc-file=SITENAME -e robots=off https://SITENAME.tumblr.com/

-----------   -----------

wget.callbacks.download_child_p = function(urlpos, parent, depth, start_url_parsed, iri, verdict, reason)

  --- haywire URL detection
  if string.match(urlpos["url"]["path"], '[+()%%]') then
    io.stdout:write("*** ILLEGAL CHARS +()% " .. " : " .. urlpos["url"]["url"] .. " from " .. parent["url"] .. " ***\n")
    io.stdout:flush()
    return false
  end

  -- these are path patterns that should never be followed
  -- TODO: probably want to allow avatar when crawling for real
  local bad_paths = {
    "_16.[gjp][ipn][fgj]$",
    "_64.[gjp][ipn][fgj]$",
    "^reblog/",
    "^rss/?$",
    --"^tagged/",
    "/embed$",
    "/amp$"
  }

  for _, path in pairs(bad_paths) do
    if string.find(urlpos["url"]["path"], path) then
      io.stdout:write("*** BLOCKING " .. path .. " : " .. urlpos["url"]["url"] .. " from " .. parent["url"] .. " ***\n")
      io.stdout:flush()
      return false
    end
  end

  local log_host = "assets.tumblr.com$"
  if string.find(urlpos["url"]["host"], log_host) then
    io.stdout:write("*** LOGGING " .. log_host .. " : " .. urlpos["url"]["url"] .. " from " .. parent["url"] .. " ***\n")
    io.stdout:flush()
  end

  -- always follow links on the following hosts
  local allowed_hosts = {
    "media.tumblr.com$",
    "static.tumblr.com$",
    -- "ajax.googleapis.com$",  -- archive.org has these from archive.bot, uncomment for offline .warc
    -- "assets.tumblr.com$"     -- archive.org has these from archive.bot, uncomment for offline .warc
  }

  if verdict == false and reason == "DIFFERENT_HOST" then
    for _, host in pairs(allowed_hosts) do
      if string.find(urlpos["url"]["host"], host) then
        io.stdout:write("*** ALLOWING HOST " .. urlpos["url"]["host"] .. " from " .. parent["url"] .. " ***\n")
        io.stdout:flush()
        return true
      end
    end
  end 

  -- always follow links matching www.tumblr.com/video
  if verdict == false and 
      reason == "DIFFERENT_HOST" and 
      urlpos["url"]["host"] == "www.tumblr.com" and 
      string.find(urlpos["url"]["path"], "^video/") then
    io.stdout:write("*** ALLOWING VIDEO " .. urlpos["url"]["url"] .. " ***\n")
    io.stdout:flush()
    return true
  end

  -- always log links matching tumblr.com/video_file
  if verdict == false and
      reason == "DIFFERENT_HOST" and
      string.find(urlpos["url"]["host"], "tumblr.com$") and
      string.find(urlpos["url"]["path"], "^video_file/") then
      io.stdout:write("*** LOGGING VIDEO " .. urlpos["url"]["url"] .. " ***\n")
      io.stdout:flush()
    return true
  end
  
  return verdict
end

-----------   -----------

wget.callbacks.get_urls = function(file, url, is_css, iri)
   io.stdout:write("### get_urls\n")
   io.stdout:flush()
   if string.find(url, "_%d+.[pjg][npi][ggf]$") then
     io.stdout:write("*** IMAGE resizes " .. url .. " ***\n")
     local url500 = url
     local url250 = url
     -- make sure wget downloads the smaller image sizes
     return {
      { url = string.gsub(url500,"_%d+.", "_500."),
             link_expect_html = 0,  link_expect_css = 0 },
      { url = string.gsub(url250,"_%d+.", "_250."),
             link_expect_html = 0,  link_expect_css = 0 }
      }
  else
    -- no new urls to add
    return { }
  end
end

-----------   -----------

wget.callbacks.httploop_result = function(url, err, http_stat)
  io.stdout:write("*** RESULT: " .. url["url"] .. " " .. tostring(http_stat["statcode"]) .. "/" .. http_stat["message"] .. "\n")
  io.stdout:flush()
  return wget.actions.NOTHING
end

-----------   -----------
