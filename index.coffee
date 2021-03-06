root = if process?
    process
else if window?
    window
else
    {}

in_browser = if window? then true else false
in_nodejs = if process? then true else false

[SHOWLOG, LOGTIME] = try
    {get_config} = require 'config'

    [(get_config 'ENV.LOG.cs_log_show_hash'),
     (get_config 'ENV.LOG.cs_log_show_time')]
catch e
    ['showlog', 'logtime']

unless root.console
    root.console =
        log: ->
        info: ->
        warn: ->
        error: ->
        assert: ->
        dir: ->
        clear: ->
        profile: ->
        profileEnd: ->

console = root.console

# HOTFIX for ie < 9 (doesn't supports console.log.apply as a function)
# link - http://stackoverflow.com/questions/5538972/console-log-apply-not-working-in-ie9
`if (Function.prototype.bind && console && typeof console.log == "object") {
    [
      "log","info","warn","error","assert","dir","clear","profile","profileEnd"
    ].forEach(function (method) {
        console[method] = this.bind(console[method], console);
    }, Function.prototype.call);
}
if (Function.prototype.bind && console && typeof console.debug == "object") {
    [
      "debug"
    ].forEach(function (method) {
        console[method] = this.bind(console[method], console);
    }, Function.prototype.call);
}
`

{partial, or_, and_, bool, is_object, is_array} = require 'libprotein'

LOGCFG = try
    log_cfg = get_config 'ENV.LOG'
    if log_cfg then log_cfg else null
    
catch e
    if in_nodejs and (is_object process.ENV) and (is_object process.ENV.LOG)
        process.ENV.LOG
    else if in_browser and (is_object window.ENV) and (is_object window.ENV.LOG)
        window.ENV.LOG
    else
        null

################################################################################
trimLeft = (s) -> s.replace /^\s+/, ""
trimRight = (s) -> s.replace /\s+$/, ""

RE1 = /^\s*\$Version=(?:"1"|1);\s*(.*)/
RE2 = /(?:^|\s+)([!#$%&'*+\-.0-9A-Z^`a-z|~]+)=([!#$%&'*+\-.0-9A-Z^`a-z|~]*|"(?:[\x20-\x7E\x80\xFF]|\\[\x00-\x7F])*")(?=\s*[,;]|$)/g

get_cookies = ->
    c = document.cookie
    v = 0
    cookies = {}

    if document.cookie.match RE1
        c = RegExp.$1
        v = 1
    
    if v is 0
        c.split(/[,;]/).map((cookie) ->
            parts = cookie.split '=', 2
            name = decodeURIComponent (trimLeft parts[0])
            cookies[name] = if parts.length > 1
                decodeURIComponent (trimRight parts[1])
            else 
                null
        )
    else
        c.match(RE2).map((name, maybe_value) ->
            cookies[name] = if maybe_value.charAt(0) is '"'
                maybe_value.substr(1, -1).replace(/\\(.)/g, "$1")
            else
                maybe_value

        )
    
    cookies

get_cookie = (name) -> get_cookies()[name]
################################################################################
        
filter = (list, f) -> i for i in list when (f i) is true

slice = (str, start, stop) -> str.substr start, stop

parse_config_hash = (hash) ->
    if hash
        parts = hash.split ';'
        grep = (pp, prefix) ->
            prefix = prefix + '='
            r = filter(pp, (p) -> (slice p, 0, prefix.length) is prefix)\
                .map((q) -> (slice q, prefix.length).split '|')

            if r.length > 0
                r.reduce((a,b) -> a.concat b)
            else
                null

        list_to_dict = (l) ->
            d = {}
            d[i] = true for i in l if l
            d

        enabled: SHOWLOG in parts
        logtime: LOGTIME in parts
        ns: list_to_dict (grep parts, 'ns')
        level: list_to_dict (grep parts, 'level')

    else
        enabled: false
        logtime: false
        ns: null
        level: null

get_cookie_hash = -> get_cookie SHOWLOG
    
get_location_hash = -> document.location.hash[1...]

merge_objects = (a, b, lc) ->
    r = {}
    r[if lc then k.toLowerCase() else k] = v for own k,v of a
    r[if lc then k.toLowerCase() else k] = v for own k,v of b
    r

submerge = (a, b, lc) ->
    if a is null and b is null
        null
    else if a is null and b isnt null
        b
    else if a isnt null and b is null
        a
    else
        merge_objects a, b, lc

merge = (a, b) ->
    if a is null and b is null
        null
    else if a is null and b isnt null
        b
    else if a isnt null and b is null
            a
    else
        enabled: a.enabled or b.enabled
        logtime: a.logtime or b.logtime
        ns: submerge a.ns, b.ns
        level: submerge a.level, b.level, true

_runtime_cfg = undefined
get_runtime_cfg = ->
    unless _runtime_cfg
        x = (merge (parse_config_hash get_location_hash()),
                   (parse_config_hash get_cookie_hash()))
        _runtime_cfg = merge LOGCFG, x
    _runtime_cfg

[enabled, log_time] = if LOGCFG.enabled?
    if in_browser
        browser_cfg = get_runtime_cfg()
        [browser_cfg.enabled or LOGCFG.enabled,
         browser_cfg.logtime or LOGCFG.logtime]
    else
        [LOGCFG.enabled, LOGCFG.logtime]
else
    [true, false]
    
log_level_enabled = (level) ->
    cfg = get_runtime_cfg()
    return true if Object.keys(cfg.level).length is 0
    level.toLowerCase() of cfg.level

log_ns_enabled = (ns) ->
    cfg = get_runtime_cfg()
    return true if Object.keys(cfg.ns).length is 0
    ns of cfg.ns

################################################################################
    

INFO = 'INFO'
WARN = 'WARN'
ERROR = 'ERROR'
DEBUG = 'DEBUG'
NOTICE = 'NOTICE'
LOG_LEVELS = [INFO, WARN, ERROR, DEBUG, NOTICE]

UNK_NS = '?'

say = (log_time, log_level, log_ns, msgs) ->
    m = [(if log_time then "[#{(new Date).valueOf()}]" else "")
         (if log_level then "[#{log_level}]" else '[NOTICE]'),
         (if log_ns then "[#{log_ns}]" else "[#{UNK_NS}]")].concat msgs
    switch log_level
        when ERROR
            console?.error? m...
        when INFO
            console?.info m...
        when DEBUG
            if console?.debug?
                console?.debug m...
            else
                console?.log m...
        when WARN
            console?.warn m...
        else
            console?.log m...

log = (log_level, log_ns, msg...) ->
    return unless enabled

    if (log_ns_enabled log_ns) and (log_level_enabled log_level)
        say log_time, log_level, log_ns, msg

nullog = ->

get_namespaced_logger = (log_ns) ->
    info:   partial log, INFO, log_ns
    warn:   partial log, WARN, log_ns
    error:  partial log, ERROR, log_ns
    debug:  partial log, DEBUG, log_ns
    notice: partial log, NOTICE, log_ns
    nullog: nullog

module.exports =
    # for use like this: {info, warn,...} = require 'console.logger'
    info:   partial log, INFO, UNK_NS
    warn:   partial log, WARN, UNK_NS
    error:  partial log, ERROR, UNK_NS
    debug:  partial log, DEBUG, UNK_NS
    notice: partial log, NOTICE, UNK_NS
    nullog: nullog

    # for use like this: {info, warn,...} = (require 'console.logger').ns 'my-ns'
    ns: get_namespaced_logger

    protocols:
        definitions:
            ILogger: [
                ['info',     [], {varargs: true}]
                ['warn',     [], {varargs: true}]
                ['error',    [], {varargs: true}]
                ['debug',    [], {varargs: true}]
                ['notice',   [], {varargs: true}]
                ['nullog',   [], {varargs: true}]
            ]
        implementations:
            # for use like this: {info, warn,...} = dispatch_impl 'ILogger', 'my-ns'
            ILogger: get_namespaced_logger
