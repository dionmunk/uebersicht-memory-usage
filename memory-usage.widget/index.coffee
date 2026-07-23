command: "memory_pressure && sysctl -n hw.memsize hw.pagesize"

refreshFrequency: '1s'

# Toggle the graph panel on/off without removing the widget
showGraph: false

historyLength: 60  # 1 min @ 1s refresh

history: []

style: """
  // grid: col 1 · row 2 · 1×1  (see LAYOUT.md)
  top 100px
  left 10px

  color var(--text, #fff)
  text-shadow: 0 1px 1px rgba(20, 1, 1, 0.10)   // inherits to all text elements
  font-family -apple-system, BlinkMacSystemFont, system-ui, sans-serif
  display: flex
  gap: 10px

  .panel
    background var(--panel-bg, rgba(#000, .15))
    -webkit-backdrop-filter: blur(var(--panel-blur, 48px))
    backdrop-filter: blur(var(--panel-blur, 48px))
    border-radius 10px
    box-sizing: border-box
    min-height: 80px       // base minimum widget height (see LAYOUT.md)

  .panel-stats
    padding 9px 10px 12px
    display: flex          // lets stats-inner fill the 80px panel height

  .panel-graph
    padding 10px

  .stats-inner
    width: 300px
    text-align: left
    position: relative
    display: flex
    flex-direction: column   // title on top, numbers + bar pushed to the bottom

  .widget-title
    font-size 10px
    text-transform uppercase
    font-weight bold
    margin-bottom: 1px

  .stats-container
    margin-top: auto       // push the numbers + bar to the panel bottom
    margin-bottom 5px      // gap between the labels and the bar
    border-collapse collapse
    table-layout: fixed

  td
    font-size: 14px
    font-weight: 300
    text-align: left
    width: 16.66%

  // Total is the last column — right-align its value and label.
  td:last-child
    text-align: right

  // Space between the numbers and their labels below them.
  .stat
    padding-bottom: 4px

  .label
    font-size 8px
    text-transform uppercase
    font-weight bold

  .bar-container
    width: 100%
    height: 6px
    border-radius: 6px
    background: var(--level-base, rgba(#fff, .2))
    position: relative
    box-shadow: 0 1px 1px rgba(20, 1, 1, 0.10)   // base bar: matches text shadow

  // Each series is its own independent layer: anchored at the left, drawn to its
  // *cumulative* width, stacked smallest-on-top. Lower series fill the area behind
  // the upper one rather than being tacked onto its right end.
  .bar
    position: absolute
    left: 0
    top: 0
    height: 6px
    border-radius: 6px
    transition: width .2s ease-in-out
    box-shadow: 1px 0 3px rgba(0, 0, 0, 0.04)   // faint separation under the cap

  .bar:nth-child(1)
    z-index: 5
  .bar:nth-child(2)
    z-index: 4
  .bar:nth-child(3)
    z-index: 3
  .bar:nth-child(4)
    z-index: 2

  // Lower layers kept quite transparent: because they stack cumulatively behind
  // the layer above, their exposed bands compound with what's behind them, so low
  // alphas here still read as a clear, well-spread ramp (wired opaque on top).
  .bar-inactive
    background: var(--series-quaternary, rgba(#fff, .2))

  .bar-compressor
    background: var(--series-tertiary, rgba(#fff, .35))

  .bar-active
    background: var(--series-secondary, rgba(#fff, .5))

  .bar-wired
    background: var(--series-primary, rgba(#fff, 1))

  .graph-container
    width: 300px
    height: 53px
    position: relative
    overflow: hidden
    border: 1px solid var(--hairline, rgba(#ccc, .125))
    border-radius: 3px
    box-sizing: border-box
    padding: 1px
    background-image: radial-gradient(var(--dot-grid, rgba(#fff, .05)) 1px, transparent 1.5px)
    background-size: 10px 10px
    background-position: -4px -4px

  svg
    display: block
    width: 100%
    height: 100%

  .line-wired
    fill: none
    stroke: var(--series-primary, rgba(#fff, 1))
    stroke-width: 1.5
    vector-effect: non-scaling-stroke
    stroke-linejoin: round
    stroke-linecap: round

  .line-active
    fill: none
    stroke: var(--series-secondary, rgba(#fff, .8))
    stroke-width: 1.5
    vector-effect: non-scaling-stroke
    stroke-linejoin: round
    stroke-linecap: round

  .line-compressor
    fill: none
    stroke: var(--series-tertiary, rgba(#fff, .6))
    stroke-width: 1.5
    vector-effect: non-scaling-stroke
    stroke-linejoin: round
    stroke-linecap: round

  .line-inactive
    fill: none
    stroke: var(--series-quaternary, rgba(#fff, .4))
    stroke-width: 1.5
    vector-effect: non-scaling-stroke
    stroke-linejoin: round
    stroke-linecap: round

  .area-wired
    fill: var(--series-primary-fill, rgba(#fff, .3))
    stroke: none

  .area-active
    fill: var(--series-secondary-fill, rgba(#fff, .25))
    stroke: none

  .area-compressor
    fill: var(--series-tertiary-fill, rgba(#fff, .2))
    stroke: none

  .area-inactive
    fill: var(--series-quaternary-fill, rgba(#fff, .15))
    stroke: none
"""

render: -> """
  <div class="panel panel-stats">
    <div class="stats-inner">
      <div class="widget-title">Memory</div>
      <table class="stats-container" width="100%">
        <tr>
          <td class="stat"><span class="wired"></span></td>
          <td class="stat"><span class="active"></span></td>
          <td class="stat"><span class="compressor"></span></td>
          <td class="stat"><span class="inactive"></span></td>
          <td class="stat"><span class="free"></span></td>
          <td class="stat"><span class="total"></span></td>
        </tr>
        <tr>
          <td class="label">wired</td>
          <td class="label">active</td>
          <td class="label">comp</td>
          <td class="label">inactive</td>
          <td class="label">free</td>
          <td class="label">total</td>
        </tr>
      </table>
      <div class="bar-container">
        <div class="bar bar-wired"></div>
        <div class="bar bar-active"></div>
        <div class="bar bar-compressor"></div>
        <div class="bar bar-inactive"></div>
      </div>
    </div>
  </div>
  #{if @showGraph then """
  <div class="panel panel-graph">
    <div class="graph-container">
      <svg preserveAspectRatio="none" viewBox="0 0 59 100">
        <polygon class="area-wired" points=""></polygon>
        <polygon class="area-active" points=""></polygon>
        <polygon class="area-compressor" points=""></polygon>
        <polygon class="area-inactive" points=""></polygon>
        <polyline class="line-wired" points=""></polyline>
        <polyline class="line-active" points=""></polyline>
        <polyline class="line-compressor" points=""></polyline>
        <polyline class="line-inactive" points=""></polyline>
      </svg>
    </div>
  </div>
  """ else ""}
"""

update: (output, domEl) ->
  lines = output.split "\n"
  totalBytes = parseInt(lines[28], 10)
  pageSize   = parseInt(lines[29], 10)
  return unless totalBytes > 0 and pageSize > 0

  usageFormat = (mb) ->
    if mb > 1024
      gb = mb / 1024
      if gb >= 10
        "#{Math.round(gb)}GB"
      else
        "#{gb.toFixed(1)}GB"
    else
      "#{parseFloat(mb.toFixed())}MB"

  usage = (pages) ->
    usageFormat (pages * pageSize) / 1024 / 1024

  updateStat = (sel, usedPages) ->
    $(domEl).find(".#{sel}").text usage(usedPages)

  freePages       = parseInt(lines[3].split(": ")[1], 10) or 0
  activePages     = parseInt(lines[12].split(": ")[1], 10) or 0
  inactivePages   = parseInt(lines[13].split(": ")[1], 10) or 0
  wiredPages      = parseInt(lines[16].split(": ")[1], 10) or 0
  compressorPages = parseInt(lines[19].split(": ")[1], 10) or 0

  $(domEl).find(".total").text usageFormat(totalBytes / 1024 / 1024)

  updateStat 'free',       freePages
  updateStat 'active',     activePages
  updateStat 'compressor', compressorPages
  updateStat 'inactive',   inactivePages
  updateStat 'wired',      wiredPages

  # Bars are independent cumulative layers (wired on top, each next one drawn to
  # the running total behind it), stacked wired→active→compressor→inactive.
  pct = (pages) -> pages * pageSize / totalBytes * 100
  cum = 0
  for [sel, pages] in [['wired', wiredPages], ['active', activePages], ['compressor', compressorPages], ['inactive', inactivePages]]
    cum += pct(pages)
    $(domEl).find(".bar-#{sel}").css "width", "#{cum}%"

  return unless @showGraph

  pctOf = (pages) -> pages * pageSize / totalBytes * 100

  @history ?= []
  @history.push
    wired:      pctOf(wiredPages)
    active:     pctOf(activePages)
    compressor: pctOf(compressorPages)
    inactive:   pctOf(inactivePages)
  @history.shift() while @history.length > @historyLength

  return if @history.length < 2

  N = @historyLength
  offset = N - 1 - (@history.length - 1)
  lastX = offset + @history.length - 1

  # Cumulative top-of-stack y-coords for each segment (lower y = higher on graph).
  buildLine = (cumFn) =>
    @history.map((s, i) -> "#{offset + i},#{100 - cumFn(s)}").join(" ")

  reverseLine = (cumFn) =>
    @history.map((s, i) -> "#{offset + i},#{100 - cumFn(s)}").reverse().join(" ")

  cumWired      = (s) -> s.wired
  cumActive     = (s) -> s.wired + s.active
  cumCompressor = (s) -> s.wired + s.active + s.compressor
  cumInactive   = (s) -> s.wired + s.active + s.compressor + s.inactive

  wiredLine      = buildLine(cumWired)
  activeLine     = buildLine(cumActive)
  compressorLine = buildLine(cumCompressor)
  inactiveLine   = buildLine(cumInactive)

  $(domEl).find('.line-wired').attr('points', wiredLine)
  $(domEl).find('.line-active').attr('points', activeLine)
  $(domEl).find('.line-compressor').attr('points', compressorLine)
  $(domEl).find('.line-inactive').attr('points', inactiveLine)

  # Each area polygon = top boundary (left→right) + bottom boundary (right→left).
  # Bottom segment closes against the baseline (y=100).
  $(domEl).find('.area-wired').attr('points', "#{wiredLine} #{lastX},100 #{offset},100")
  $(domEl).find('.area-active').attr('points', "#{activeLine} #{reverseLine(cumWired)}")
  $(domEl).find('.area-compressor').attr('points', "#{compressorLine} #{reverseLine(cumActive)}")
  $(domEl).find('.area-inactive').attr('points', "#{inactiveLine} #{reverseLine(cumCompressor)}")
