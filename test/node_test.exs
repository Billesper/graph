defmodule NodeTest do
  use ExUnit.Case
  doctest Graph.Node

  import Graph.Node
  alias Graph.Node


  test "new" do
    id = "3"
    n = new(id)
    assert n == %Node{id: id, data: nil, adjacent: MapSet.new}

    data = {:sample, :data}
    n = new(id, data)
    assert n == %Node{id: id, data: data, adjacent: MapSet.new}
    
  end

  test "set_id and get_id" do
    id = "5"
    n = new(id)
    assert get_id(n) == id

    id = "7"
    n = set_id(n, id)
    assert get_id(n) == id
  end

  test "get_data and set_data" do
    id = "3"
    n = new(id)

    assert get_data(n) == nil

    data = {:sample, :data}
    n = set_data(n, data)

    assert get_data(n) == data
  end
  
  test "add_adjacent, remove_adjacent, and has_adj_node?" do
    id = "3"
    n = new(id)

    a1_id = "5"
    a2_id = "6"

    n = add_adjacent(n, a1_id)
    |> add_adjacent(a2_id)

    aset = MapSet.new |> MapSet.put(a1_id) |> MapSet.put(a2_id)
    assert n == %Node{adjacent: aset, id: id, data: nil}
    assert has_adj_node?(n, a1_id) and has_adj_node?(n, a2_id)

    n = remove_adjacent(n, a1_id)
    aset = MapSet.delete(aset, a1_id)

    assert n == %Node{adjacent: aset, id: id, data: nil}
    assert not has_adj_node?(n, a1_id) and has_adj_node?(n, a2_id)
    
  end
    
end
