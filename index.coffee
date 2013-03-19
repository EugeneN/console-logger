bootstrapper = try
    require 'bootstrapper'
catch e
    null

if bootstrapper
    ENV = bootstrapper.ENV
    # hack
    ENV.LOG or= {}
    ENV.LOG.GREP_PATTERN or= {}
    ENV.LOG.DROP_PATTERN or= {}

    match = (grep_or_drop, default_, log_level, msg) ->
        if bool ENV.LOG[grep_or_drop][log_level]
            (or_ (msg.map (s) -> !!(or_ ENV.LOG[grep_or_drop][log_level].map (p) -> p.test s)))
        else
            default_

    set_pattern = (grep_or_drop, args...) ->
        if args.length is 1
            pattern = args[0]
            LOG_LEVELS.map (log_level) ->
                ENV.LOG[grep_or_drop][log_level] or= []
                ENV.LOG[grep_or_drop][log_level].push pattern

        else
            [log_level, pattern] = args
            if log_level in LOG_LEVELS
                ENV.LOG[grep_or_drop][log_level] or= []
                ENV.LOG[grep_or_drop][log_level].push pattern
            else
                throw "Unknown log level: #{log_level}"

        true

    clear = (grep_or_drop, log_level) ->
        if log_level in LOG_LEVELS
            ENV.LOG[grep_or_drop][log_level] = []
        else
            LOG_LEVELS.map (log_level) ->
                ENV.LOG[grep_or_drop][log_level] = []

        true

    # hack
    ENV.ROOT_NS.grep = partial set_pattern, GREP_PATTERN
    ENV.ROOT_NS.drop = partial set_pattern, DROP_PATTERN
    ENV.ROOT_NS.clear_grep = partial clear, GREP_PATTERN
    ENV.ROOT_NS.clear_drop = partial clear, DROP_PATTERN

INFO = 'INFO'
WARN = 'WARN'
ERROR = 'ERROR'
DEBUG = 'DEBUG'
GREP_PATTERN = 'GREP_PATTERN'
DROP_PATTERN = 'DROP_PATTERN'
LOG_LEVELS = [INFO, WARN, ERROR, DEBUG]

{partial, or_, and_, bool} = require 'libprotein'

logger_proto = [
    ['info',    [], {varargs: true}]
    ['warn',    [], {varargs: true}]
    ['error',   [], {varargs: true}]
    ['debug',   [], {varargs: true}]
]

say = (a...) -> console?.log a...


valid_for_inclusion = if bootstrapper
    partial match, GREP_PATTERN, true
else
    -> true

valid_for_exclusion = if bootstrapper
    partial match, DROP_PATTERN, false
else
    -> false
        
log_level_enabled = (log_level) ->
    if bootstrapper
        ENV.LOG[log_level] is true
    else
        true
        
log = (log_level, msg...) ->
    if (and_ (log_level_enabled log_level),
             (valid_for_inclusion log_level, msg),
             (not valid_for_exclusion log_level, msg))
        
        say (["[#{log_level}]"].concat msg)...

info =  partial log, INFO
warn =  partial log, WARN
error = partial log, ERROR
debug = partial log, DEBUG

console_logger = (opts) -> {info, warn, error, debug}



module.exports =
    info: info
    warn: warn
    error: error
    debug: debug

    protocols:
        definitions:
            ILogger: logger_proto
        implementations:
            ILogger: console_logger
