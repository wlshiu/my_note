define save-bt
    if $argc != 1
        help save-bt
    else
        set logging file $arg0
        set logging on
        set logging off
    end
end
document save-bt
Usage: save-bt ~/bt.log
end


define save-bp
    if $argc != 1
        help save-bp
    else
        save breakpoints $arg0
    end
end
document save-bp
Usage: save-bp ~/bp.rec
end

define reload-bp
    if $argc != 1
        help reload-bp
    else
        source $arg0
    end
end
document reload-bp
Usage: source ~/bp.rec
end

