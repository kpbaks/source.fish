function _source_install --on-event source_install
    # Set universal variables, create bindings, and other initialization logic.
end

function _source_update --on-event source_update
	# Migrate resources, print warnings, and other update logic.
end

function _source_uninstall --on-event source_uninstall
	# Erase "private" functions, variables, bindings, and other uninstall logic.
end
