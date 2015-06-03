hljs   = require 'highlight.js' # syntax highlighting
marked = require 'marked'

renderer = new marked.Renderer
# override default heading renderer so we can generate IDs that match GitHub's algorithm.
# this means I don't have to go replace each anchor link by hand when updating...
renderer.heading = (text, level) ->
  slug = text.toLowerCase()
    .replace(/&gt;/g, '>')      # unescape >
    .replace(/<\/?code>/g, '')  # remove <code> tags from `wrapper`
    .replace(/\s/g, '-')        # whitespace becomes dashes
    .replace(/[^a-z0-9-]/g, '') # remove non-alphanumeric characters
  return "<h#{level} id=\"#{slug}\">#{text}</h#{level}>"

options =
  gfm: true
  breaks: true
  renderer: renderer
  highlight: (code, lang) ->
    (if lang then hljs.highlight(lang, code) else hljs.highlightAuto(code)).value

# render a markdown string to HTML using the options above
module.exports = (md) -> marked(md, options)
