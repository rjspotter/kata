# x = -3.0:0.1:3.0
# f(x) = x^2
# y = f.(x)

using Pkg
using CSV
using DataFrames
using StatsBase
using Statistics

const global dataframe = open("/home/ubuntu/data/kc_house_data/kc_house_data.csv") |> CSV.File |> DataFrame

const global label = :price
const global threashold = 2500
const global max_branches = 10

function partition(feature_values)
    x = feature_values |> countmap |>  cm -> filter((x -> x.second > 3), cm) |> collect |> size |> first
  if x <= max_branches
    feature_values |> unique .|> (x -> (first = x, second = x))
  else
    acc = []
    step = feature_values |> std
    max = feature_values |> maximum
    fst = feature_values |> minimum
    snd = fst + step
    while snd < max
      # println(" fst: $fst ,  snd: $snd ,  max: $max ,  step: $step , ")
      push!(acc, (first = fst, second = snd))
      fst = snd
      snd = snd + step
    end
    acc
  end
end

function inpartition(tup, val)
  tup.first == val || (val >= tup.first && val < tup.second)
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
  sum(entropy_diff) / length(values)
end

function gainz(df, ignore)
  acc = Dict()
  Threads.@threads for n in names(df)
    if n == label || n in ignore
      #nop
    else
      acc[n] = infogain(df, n)
    end
  end
  acc
end

function next_feature(feature_entropies, ignore)
  function largest(a, b)
    if b.first in ignore
      a
    else
      a.second > b.second ? a : b
    end
  end
  candidate = reduce(largest, feature_entropies)
  candidate.first
end

function build_tree(df, ignore=[], depth=0)
  max_depth = (df |> names |> size |> first) - (ignore |> size |> first) - 1
  if (std(df[label]) < threashold) || depth >= max_depth
    df[label]
  else
    feature = next_feature(gainz(df, ignore), ignore)
    new_nodes = Dict()
    Threads.@threads for v in partition(df[feature])
      new_nodes[v] = build_tree(
        filter(x -> inpartition(v, x[feature]), df),
        cat(ignore, feature, dims=1),
        depth + 1
      )
    end
    Dict(feature => new_nodes)
  end
end

# tree = build_tree(dataframe, [:id, :sqft_lot15, :sqft_living15, :date]) && true

function treewalk(item, branch::Array, value=0)
  branch
end

function treewalk(item, branch::Dict, value=0)
  ks = tree |> keys |> collect
  if ks |> size |> first == 1
    key = ks |> first
    treewalk(item, branch[key], (item[key] |> first))
  else
    filter(x -> inpartition(value, x), ks)
  end
end

