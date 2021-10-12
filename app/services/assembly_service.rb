# frozen_string_literal: true

class AssemblyService
  # given an item and a goal, "assemble" combinations to match the goal
  # using item and any sub_items
  attr_accessor :map, :remainder, :assembly, :goal, :item, :combination

  def initialize(combination, goal)
    @combination = combination
    @assembled = 0
    @remainder = goal
    @log = []
  end
end


# I envision: Assembly.find(9).assembly_map(458)
# [{:uid=>"C031", :can_make=>45, :remainder=>413}, {:uids=>["P072", "P069", "C030"], :can_make=>1, :remainder=>412}]
# and so on, treeing down

# this highlights that sub_assemblies all have to work together to contribute towards the remainder.
# C030 only has 1, so the max contribution towards an extra CO31 is 1
# UNLESS C030 has sub assemblies

# maybe maps should only be 1 level deep.
# if you then ran this for C030, you'd discover if any more could be assembled.

# note that this will actually be a method in Itemable, since Assembly wouldn't be able to elegantly batch the assemblies


# THE OTHER OPTION
# more like QuantityAndDepthCalculationJob
# Every technology has quantity, which lists every item that makes it
# Technology.find(3).quantities
#  =>
# {"C022"=>1, <---- maybe it's easier to build a struct that adds the available_count to each of these? But then I still don't know how to relationalize that information (like that C031 contains C030)
#  "C023"=>1,
#  "C024"=>1,
#  "C026"=>1,
#  "C029"=>1,
#  "C030"=>1,
#  "C031"=>1,
#  "C033"=>1,
#  "C043"=>1,
#  "C048"=>1,
#  "C049"=>1,
#  "C050"=>1,
#  "M006"=>0.08125,
#  "M008"=>0.05,
#  "M009"=>1.0,
#  "P005"=>1,
#  "P007"=>1,
#  "P008"=>1,
#  "P035"=>1,
#  "P036"=>1,
#  "P042"=>2,
#  "P066"=>1,
#  "P067"=>1,
#  "P068"=>1,
#  "P069"=>1,
#  "P071"=>1,
#  "P072"=>2,
#  "P073"=>1,
#  "P074"=>1,
#  "P075"=>1,
#  "P079"=>1,
#  "P081"=>1,
#  "P082"=>1,
#  "P083"=>1,
#  "P084"=>1,
#  "P085"=>2,
#  "P086"=>2,
#  "P092"=>1,
#  "P112"=>1,
#  "P168"=>2}
