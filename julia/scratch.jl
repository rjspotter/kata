using Pkg
using CSV
using DataFrames
using StatsBase
using Statistics
# using ASTInterpreter2
# using DebuggerFramework

const global dataframe = open("/home/ubuntu/data/kc_house_data/kc_house_data.csv") |> CSV.File |> DataFrame

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
  # println(item[:id])
  ks = (branch |> keys |> collect)
  if (ks |> size |> first) < 1
    (item, branch, value)
  elseif (ks |> size |> first) == 1 && (ks |> first |> typeof) == Symbol
    ky = ks |> first
    # println(ky)
    new_branch = branch[ky]
    treewalk(item, new_branch, (item[ky] |> first))
  else
    # println("+++++++++++++++")
    # println(value)
    # println(ks)
    # println("---------------")
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
  upper = slice_size

  while lower < max
    subset = full_set[lower:upper, :]
    tree = build_tree(subset, 1000)
    mn = subset[label] |> minimum
    mx = subset[label] |> maximum
    push!(acc, (tree = tree, min = mn, max = mx))
    lower = upper
    upper = upper + slice_size
    if upper > max
      upper = max
    end
    @assert upper <= max
  end
  acc
end

# feature_frame = dataframe[dataframe[:bedrooms] .<= 10, :]

# test_set = copy(feature_frame[1:4323, :])
# train_set = copy(feature_frame[4324:21611, :])
# # sort!(train_set, label)
# for ing in [:id, :sqft_lot15, :sqft_living15, :date, :lat, :long]
#   deletecols!(train_set, ing)
# end

# trees = many_trees(train_set, 21);

# global myerr = []
# for i in 1:size(test_set, 1)
#   item = test_set[i, :]
#   predictions = []
#   for t in trees
#     p = treewalk(item, t.tree)
#     if p == t.min || p == t.max
#       #nop
#     else
#       push!(predictions, p)
#     end
#   end
#   predict = mean(predictions)
#   push!(myerr, abs(predict - item[label]))
# end

# println(mean(myerr))


# Next:  Build the ability for trees to return an "I don't know" answer
#   create a forrest of overlapping trees

function slices(arr, c)
  max = size(arr, 1)
  slice_size = trunc(Int64, ceil(max / c))
  lower = 1
  upper = slice_size
  while lower < max
    subset = arr[lower:upper, :]
    subset[:A] |> minimum
    lower = upper
    next = upper + slice_size
    if next >= max
      upper = max
    else
      upper = next
    end
  end
end

a = DataFrame(A = 1:81)
slices(a, 7)
