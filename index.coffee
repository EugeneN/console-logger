root = if process?
    process
else if window?
    window
else
    {}

in_browser = if window? then true else false
in_nodejs = if process? then true else false

{showlog, logtime} = try
    {get_config} = require 'config'

    showlog: get_config 'ENV.LOG.cs_log_show_hash'
    logtime: get_config 'ENV.LOG.cs_log_show_time'
catch e
    showlog: 'showlog'
    logtime: 'logtime'

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


# HOTFIX for ie < 9 (doesn't supports console.log.apply as a function)
# link - http://stackoverflow.com/questions/5538972/console-log-apply-not-working-in-ie9
`if (Function.prototype.bind && console && typeof console.log == "object") {
    [
      "log","info","warn","error","assert","dir","clear","profile","profileEnd"
    ].forEach(function (method) {
        console[method] = this.bind(console[method], console);
    }, Function.prototype.call);
}`

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

####################
# good code, but does not work in ie7
# parse_location_hash = (hash) ->
#     parts = hash.split ';'
#     grep = (p, prefix) ->
#         prefix = prefix + '='
#         r = p.filter((p) -> p[0...prefix.length] is prefix)
#              .map((p) -> p[prefix.length...].split '|')

#         if r.length > 0
#             r.reduce((a,b) -> a.concat b)
#         else
#             null

#     enabled: showlog in parts
#     ns: grep parts, 'ns'
#     level: grep parts, 'level'


# code for ie7
filter = (list, f) -> i for i in list when (f i) is true

slice = (str, start, stop) -> str.substr start, stop

parse_location_hash = (hash) ->
    parts = hash.split ';'
    grep = (pp, prefix) ->
        prefix = prefix + '='
        r = filter(pp, (p) -> (slice p, prefix.length) is prefix)
             .map((q) -> (slice q, prefix.length).split '|')

        if r.length > 0
            r.reduce((a,b) -> a.concat b)
        else
            null

    enabled: showlog in parts
    ns: grep parts, 'ns'
    level: grep parts, 'level'


hash_level = (level) ->
    if in_browser
        hash_cfg = parse_location_hash document.location.hash[1...]
        return true if hash_cfg.level is null

        if level.toLowerCase() in hash_cfg.level.map((i) -> i.toLowerCase()) 
            true 
        else
            false
    else
        false

hash_ns = (ns) ->
    if in_browser
        hash_cfg = parse_location_hash document.location.hash[1...]
        return true if hash_cfg.ns is null

        if ns in hash_cfg.ns then true else false
    else
        false
####################
    

INFO = 'INFO'
WARN = 'WARN'
ERROR = 'ERROR'
DEBUG = 'DEBUG'
NOTICE = 'NOTICE'
LOG_LEVELS = [INFO, WARN, ERROR, DEBUG, NOTICE]

UNK_NS = 'UNK_NS'

say = (log_level, log_ns, msgs) ->
    log_time = document.location.hash.indexOf(logtime) > -1

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

log_level_enabled = (log_level) ->
    cfg_level = if LOGCFG then (LOGCFG.level?[log_level] is true) else true
    if in_browser
        (hash_level log_level) #or cfg_level
    else
        cfg_level

log_ns_enabled = (log_ns) ->
    cfg_ns = if LOGCFG then (LOGCFG.ns?[log_ns] is true) else false
    if in_browser
        (hash_ns log_ns) #or cfg_ns
    else
        cfg_ns

log = (log_level, log_ns, msg...) ->
    enabled = if LOGCFG.enabled?
        LOGCFG.enabled
        if in_browser
            hash_cfg = parse_location_hash document.location.hash[1...]
            hash_cfg.enabled or LOGCFG.enabled
        else
            LOGCFG.enabled
    else
        true

    return unless enabled

    if (log_ns_enabled log_ns) and (log_level_enabled log_level)
        say log_level, log_ns, msg

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
