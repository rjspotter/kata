using CSV
using DataFrames
using Pkg
using Query
using StatsBase
using Statistics

# const global dataframe = open("/home/ubuntu/data/kc_house_data/kc_house_data.csv") |> CSV.File |> DataFrame
const global dataframe = open("/home/ubuntu/data/house-prices-advanced-regression-techniques/train.csv") |> CSV.File |> DataFrame

mapping = Dict(
  :MSZoning => Dict(
    "RP" => 1,
    "RL" => 2,
    "RM" => 3,
    "RH" => 4,
    "FV" => 5,
    "A"  => 6,
    "I"  => 7,
    "C (all)" => 8
  ),
  :Street => Dict("Pave" => 2, "Grvl" => 1, "NA" => 0),
  :Alley => Dict("Pave" => 2, "Grvl" => 1, "NA" => 0),
  :LotShape => Dict(
    "Reg" => 0,
    "IR1" => 1,
    "IR2" => 2,
    "IR3" => 3
  ),
  :LandContour => Dict(
    "Lvl" => 0,
    "Bnk" => 1,
    "Low" => 2,
    "HLS" => 3
  ),
  :Utilities => Dict(
    "AllPub" => 0,
    "NoSewr" => 1,
    "NoSeWa" => 2,
    "ELO"    => 3
  ),
  :LotConfig => Dict(
    "Inside"  => 0,
    "Corner"  => 1,
    "CulDSac" => 2,
    "FR2"     => 3,
    "FR3"     => 4
  ),
  :LandSlope => Dict(
    "Gtl" => 0,
    "Mod" => 1,
    "Sev" => 2
  ),
  :Neighborhood => Dict(
    "CollgCr" => 0,
    "Veenker" => 1,
    "Crawfor" => 2,
    "NoRidge" => 3,
    "Mitchel" => 4,
    "Somerst" => 5,
    "NWAmes"  => 6,
    "OldTown" => 7,
    "BrkSide" => 8,
    "Sawyer"  => 9,
    "NridgHt" => 10,
    "NAmes"   => 11,
    "SawyerW" => 12,
    "IDOTRR"  => 13,
    "MeadowV" => 14,
    "Edwards" => 15,
    "Timber"  => 16,
    "Gilbert" => 17,
    "StoneBr" => 18,
    "ClearCr" => 19,
    "NPkVill" => 20,
    "Blmngtn" => 21,
    "BrDale"  => 22,
    "SWISU"   => 23,
    "Blueste" => 24,
  )
)
function foo(val::Array{Union{Missing, String}})
  println("tryhing")
end
function foo(val::Array{Union{Missing, Number}})
  println("number")
end
function do_map(oldval::String, mapping::Dict)
  @assert in(oldval, keys(mapping))
  mapping[oldval]
end

function na_is_zero(old::String)
  @assert occursin(r"^NA|[0-9]+$", old)
  old == "NA" ? 0 : parse(Int64, old)
end

const global label = :price

function large_partition(feature_values)
  acc = []
  step = feature_values |> std
  max = feature_values |> maximum
  fst = 0
  snd = (feature_values |> minimum) + step
  while snd < (max - 1)
    proposed = (first = fst, second = snd)
    if (filter(x -> inpartition(proposed, x), feature_values) |> size |> first) > 0
      push!(acc, proposed)
      fst = snd
    end
    snd = snd + step
  end
  proposed = (first = fst, second = Inf32)
  push!(acc, proposed)
  acc
end

function small_partition(feature_values)
  feature_values = sort(feature_values)
  acc = []
  fst = 0
  for i in unique(feature_values)
    snd = i
    proposed = (first = fst, second = snd)
    if (filter(x -> inpartition(proposed, x), feature_values) |> size |> first) > 0
      push!(acc, proposed)
      fst = snd
    end
  end
  proposed = (first = fst, second = Inf32)
  push!(acc, proposed)
  acc
end

function partition(feature_values)
  if (feature_values |> unique |> length) > 15
    large_partition(feature_values)
  else
    small_partition(feature_values)
  end
end

function inpartition(tup, val)
  (val >= tup.first && val < tup.second)
end

function entropy(data)
  len = data |> length |> float
  function item_entropy(category)
    ratio = float(category) / len
    -1 * ratio * log2(ratio)
  end
  data |> countmap |> values |> v -> map(item_entropy, v) |> sum
end

function infogain(df, feature)
  function entropy_with_value(val)
    entropy(filter(x -> inpartition(val, x[feature]), df)[label])
  end
  baseline = entropy(df[label])
  values = df[feature] |> partition
  entropy_diff = values .|> entropy_with_value .|> y -> baseline - y
  l = length(values)
  if l < 1
    0
  else
    sum(entropy_diff) / l
  end
end

function gainz(df)
  acc = Dict()
  for n in names(df)
    if n == label
      #nop
    else
      acc[n] = infogain(df, n)
    end
  end
  acc
end

function next_feature(feature_entropies)
  function largest(a, b)
    if b.first == label
      a
    else
      a.second > b.second ? a : b
    end
  end
  candidate = reduce(largest, feature_entropies)
  candidate.first
end

function small_difference(df, threashold)
  min = (df[label] |> minimum)
  max = (df[label] |> maximum)
  (max - min) < threashold
end

function build_tree(df, threashold)
  if (df |> names |> size |> first) < 2 || small_difference(df, threashold)
    df[label]
  else
    feature = df |> gainz |> next_feature
    new_nodes = Dict()
    for v in partition(df[feature])
      subframe = filter(x -> inpartition(v, x[feature]), df)
      deletecols!(subframe, feature)
      subtree = build_tree(subframe, threashold)
      new_nodes[v] = subtree
    end
    Dict(feature => new_nodes)
  end
end

function treewalk(item, branch::Union, value=0)
  sum(branch) / length(branch)
end

function treewalk(item, branch::Array, value=0)
  sum(branch) / length(branch)
end


function treewalk(item, branch::Dict, value=0)
  ks = (branch |> keys |> collect)
  if (ks |> size |> first) < 1
    (item, branch, value)
  elseif (ks |> size |> first) == 1 && (ks |> first |> typeof) == Symbol
    ky = ks |> first
    new_branch = branch[ky]
    treewalk(item, new_branch, (item[ky] |> first))
  else
    ky = filter(x -> inpartition(x, value), ks) |> first
    new_branch = branch[ky]
    treewalk(item, new_branch)
  end
end

function many_trees(full_set, slices)
  @assert slices > 1

  acc = []
  max = size(full_set, 1)
  @assert max > 0
  @assert typeof(max) == Int64

  slice_size = trunc(Int64, ceil(max / slices))
  @assert slice_size > 0
  @assert typeof(slice_size) == Int64
  lower = 1
  upper = slice_size * 2

  while lower < max
    subset = full_set[lower:upper, :]
    tree = build_tree(subset, 1000)
    mn = subset[label] |> minimum
    mx = subset[label] |> maximum
    push!(acc, (tree = tree, min = mn, max = mx))
    lower = lower + slice_size
    upper = upper + slice_size
    if upper > max
      upper = max
    end
    @assert upper <= max
  end
  acc
pend

feature_frame = dataframe[dataframe[:bedrooms] .<= 10, :]

test_set = copy(feature_frame[1:4323, :])
train_set = copy(feature_frame[4324:21611, :])
# sort!(train_set, label)
for ing in [:id, :sqft_lot15, :sqft_living15, :date, :lat, :long]
  deletecols!(train_set, ing)
end

trees = many_trees(train_set, 21);

global myerr = []
for i in 1:size(test_set, 1)
  item = test_set[i, :]
  predictions = []
  for t in trees
    p = treewalk(item, t.tree)
    if p == t.min || p == t.max
      #nop
    else
      push!(predictions, p)
    end
  end
  predict = mean(predictions)
  err = abs(log(predict) - log(item[label]))
  # if err > 100000
  #   println(sort(predictions))
  #   println(predict)
  #   println(item[label])
  # end
  push!(myerr, err)
end

println(sqrt(mean(myerr.^2.)))

#unsorted single tree
# julia> println(mean(myerr))
# 184383.37709441825

# julia> println(sqrt(mean(myerr.^2.)))
# 334189.8279692254


# unsorted & sliced
# julia> println(mean(myerr))
# 151868.14472280702

# julia> println(sqrt(mean(myerr.^2.)))
# 280462.39544090594


# sorted & sliced
# julia> println(mean(myerr))
# 235164.47230174634

# julia> println(sqrt(mean(myerr.^2.)))
# 385158.98424631305


# unsorted & overlapping slices
# julia> println(mean(myerr))
# 147712.1182026513

# julia> println(sqrt(mean(myerr.^2.)))
# 264368.5619372746


# sorted & overlapping slices
# julia> println(mean(myerr))
# 236879.06318660572

# julia> println(sqrt(mean(myerr.^2.)))
# 379433.6094573489


  function 
