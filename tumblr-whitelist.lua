-- tumblr.lua

-- Print contents of `tbl`, with indentation.
-- `indent` sets the initial level of indentation.
function tprint (tbl, indent)
  if not indent then indent = 0 end
  for k, v in pairs(tbl) do
    formatting = string.rep("  ", indent) .. k .. ": "
    if type(v) == "table" then
      io.stdout:write(formatting .. "\n")
      tprint(v, indent+1)
    elseif type(v) == 'boolean' then
      io.stdout:write(formatting .. tostring(v) .. "\n")      
    else
      io.stdout:write(formatting .. v .. "\n")
    end
  end
  io.stdout:flush()
end

wget.callbacks.download_child_p = function(urlpos, parent, depth, start_url_parsed, iri, verdict, reason)
  -- io.stdout:write("### download_child_p\n")
  -- io.stdout:write("        url: " .. urlpos["url"]["url"] .. "\n")
  -- io.stdout:write("link_inline: " .. urlpos["link_inline_p"] .. "\n")
  -- io.stdout:write("    verdict: " .. tostring(verdict) .. "\n")
  -- io.stdout:write("     reason: " .. tostring(reason) .. "\n")
  -- -- tprint(urlpos, 1)
  -- io.stdout:flush()

  io.stdout:write("*** URL: " .. urlpos["url"]["url"] .. " " .. tostring(verdict))
  if not verdict then
    io.stdout:write(" " .. reason)
  end
  io.stdout:write("\n")
  io.stdout:flush()

  -- these are path patterns that should never be followed
  -- TODO: probably want to allow avatar when crawling for real
  local bad_paths = {
    "^rss$",
    "^rss/",
    "^reblog/",
    "^avatar_"
  }

  for _, path in pairs(bad_paths) do
    if string.find(urlpos["url"]["path"], path) then
      io.stdout:write("*** BLOCKING " .. path .. " ***\n")
      io.stdout:flush()
      return false
    end
  end

  -- always follow links on the following hosts
  local allowed_hosts = {
    "media.tumblr.com$",
    "assets.tumblr.com$",
    "static.tumblr.com$",
    "ajax.googleapis.com$"
  }

  if verdict == false and reason == "DIFFERENT_HOST" then
    for _, host in pairs(allowed_hosts) do
      if string.find(urlpos["url"]["host"], host) then
        io.stdout:write("*** ALLOWING HOST " .. urlpos["url"]["host"] .. " ***\n")
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

  -- always follow links matching tumblr.com/video_file
  if verdict == false and
      reason == "DIFFERENT_HOST" and
      string.find(urlpos["url"]["host"], "tumblr.com$") and
      string.find(urlpos["url"]["path"], "^video_file/") then
    io.stdout:write("*** ALLOWING VIDEO " .. urlpos["url"]["url"] .. " ***\n")
    io.stdout:flush()
    return true
  end

  return verdict
end

-- wget.callbacks.get_urls = function(file, url, is_css, iri)
--   io.stdout:write("### get_urls\n")
--   io.stdout:flush()
--   local urls = {}
--   return urls
-- end

wget.callbacks.httploop_result = function(url, err, http_stat)
  io.stdout:write("*** RESULT: " .. url["url"] .. " " .. tostring(http_stat["statcode"]) .. "/" .. http_stat["message"] .. "\n")
  io.stdout:flush()
  return wget.actions.NOTHING
end