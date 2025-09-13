SimpleCov.start do
  enable_coverage :line
  add_filter %r{/modules/.*/scripts/}
  add_filter %r{/modules/.*/tests/}
  add_filter %r{/modules/lib/}
  add_filter %r{/modules/manage/}
  add_filter %r{/core/}
end
