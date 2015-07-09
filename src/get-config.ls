require! <[ rc ./default-config deep-extend ]>

module.exports = (opts = {}) -> rc 'arch', deep-extend(default-config, opts)
