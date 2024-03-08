# frozen_string_literal: true

class LogParser
  IGNORE_WORDS = %w[Exit ClientConnect ClientBegin ClientDisconnect Item].freeze
  START_GAME = 'InitGame'
  END_GAME = 'ShutdownGame'
  KILL = 'Kill'
  WORLD_PLAYER = '<world>'
  CLIENTUSERINFO = 'ClientUserinfoChanged'
  WORLD_KILLER_PATTERN = /#{Regexp.escape('killed')}\s*(\w+)/
  KILLER_PATTERN = /(?<= )([^ ]+)(?= killed)/
  DEATH_CAUSE_PATTERN = /#{Regexp.escape('by')}\s*(\w+)/
  PLAYER_PATTERN = /n\\(.*?)\\t/

  def initialize(file_name)
    @log_file = File.open(file_name, 'r')
    @matches = {}
    @match_counter = 1
    @players = []
    @total_kills = 0
    @match_kills = []
    @match_death_causes = []
    @match_world_kills = []
    @non_killer_players = {}
  end

  def parser
    @log_file.each_line do |line|
      next if include_ignored_words?(line)
      next if started_game?(line)

      if kill?(line)
        @total_kills += 1

        kill_data(line, @match_world_kills, @match_kills, @match_death_causes)
      end

      @players.append(line.match(PLAYER_PATTERN)[1]) if user_info?(line)

      next unless ended_game?(line)

      match_data(@total_kills, @match_kills, @match_world_kills, @match_death_causes)
      reset_match
      @match_counter += 1
    end

    puts @matches
    @matches
  end

  def include_ignored_words?(line)
    results = IGNORE_WORDS.map { |word| line.include?(word) ? true : false }.uniq

    results.include?(true)
  end

  def started_game?(line)
    line.include?(START_GAME)
  end

  def kill?(line)
    line.include?(KILL)
  end

  def world_player?(line)
    line.include?(WORLD_PLAYER)
  end

  def world_killer(line)
    line.match(WORLD_KILLER_PATTERN)[1]
  end

  def killer(line)
    line.match(KILLER_PATTERN)[1]
  end

  def death_cause(line)
    line.match(DEATH_CAUSE_PATTERN)[1]
  end

  def kill_data(line, match_world_kills, match_kills, match_death_causes)
    if world_player?(line)
      match_world_kills.append(world_killer(line))
    else
      match_kills.append(killer(line))
    end

    match_death_causes.append(death_cause(line))
  end

  def user_info?(line)
    line.include?(CLIENTUSERINFO)
  end

  def ended_game?(line)
    line.include?(END_GAME)
  end

  def match_data(total_kills, match_kills, match_world_kills, match_death_causes)
    match_name = "game-#{@match_counter}"

    @matches[match_name] = {
      'total_kills': total_kills,
      'players': @players.uniq,
      'kills': kills_data(match_kills.tally, match_world_kills.tally),
      'kills_by_means': match_death_causes.tally
    }
  end

  def reset_match
    @total_kills = 0
    @match_kills = []
    @match_death_causes = []
    @match_world_kills = []
  end

  def add_missing_keys(kills, world_kills)
    world_kills.each_key { |key| kills[key] = 0 }

    kills
  end

  def decrement_world_kills_from_kills(kills, world_kills)
    kills.merge(world_kills) { |_key, kill_value, world_value| kill_value - world_value }
  end

  def kills_data(kills, world_kills)
    merged_data = add_missing_keys(kills, world_kills)
    decrement_world_kills_from_kills(merged_data, world_kills)
  end

  def non_killer_players
    players = @players.map { |player| player unless @match_kills.include?(player) }
    players.each do |player|
      @non_killer_players[player] = 0
    end

    @non_killer_players
  end

  def without_empty_values
    filtered_data = @matches.map { |_key, value| value[:kills] }.reject { |h| h == {} }

    filtered_data.map do |data|
      data.merge(non_killer_players) do |key, filtered_value, non_killer_value|
        data.key?(key) ? filtered_value : non_killer_value
      end
    end
  end

  def ranking
    result = {}

    without_empty_values.each do |hash|
      hash.each_key do |key|
        if result.key?(key)
          result[key] += [hash[key]]
        else
          result[key] ||= 0
          result[key] = [hash[key]]
        end
      end
    end

    ranking_result(result)
  end

  private

  def sum_and_sort_ranking(result)
    sum = {}

    result.each do |name, values|
      sum[name] = values.sum
    end

    sum.sort_by { |_key, value| value }.reverse.to_h
  end

  def ranking_result(result)
    ranking = { ranking: sum_and_sort_ranking(result) }

    puts ranking

    ranking
  end
end

log = LogParser.new('qgames.log')
log.parser
log.ranking
