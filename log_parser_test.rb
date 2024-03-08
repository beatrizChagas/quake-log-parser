# frozen_string_literal: true

require_relative 'log_parser'
require 'rspec'

RSpec.describe 'LogParser' do
  before(:each) do
    @log = LogParser.new('qgame_test.log')
  end

  describe '#parser' do
    it 'returns parsed data' do
      expect(@log.parser).to eq(parser_result)
    end
  end

  describe '#ranking' do
    it 'returns ranking data' do
      @log.parser
      expect(@log.ranking).to eq(ranking_result)
    end
  end

  private

  def parser_result
    {
      'game-1' => {
        total_kills: 15,
        players: ['Isgalamido', 'Dono da Bola', 'Mocinha', 'Zeh'],
        kills: { 'Isgalamido' => -8, 'Zeh' => -2, 'Dono' => -1 },
        kills_by_means: { 'MOD_TRIGGER_HURT' => 9, 'MOD_ROCKET_SPLASH' => 3, 'MOD_FALLING' => 2,
                          'MOD_ROCKET' => 1 }
      }
    }
  end

  def ranking_result
    {
      ranking: {
        'Mocinha' => 0, 'Dono da Bola' => 0, 'Dono' => -1, 'Zeh' => -2, 'Isgalamido' => -8
      }
    }
  end
end
