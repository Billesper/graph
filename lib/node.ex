defmodule Graph.Node do

  alias Graph.Node

  @moduledoc """
  Documentation for Graph.Node
  """
  @enforce_keys [:id]
  defstruct id: nil, adjacent: %MapSet{}, data: nil

  @type adjacency_list :: MapSet.t(binary)
  @type t() :: %Node{id: binary, adjacent: adjacency_list}
  @type t(struct) :: %Node{id: binary, adjacent: adjacency_list, data: struct}
  
  @doc """
  Returns a new Node struct with id.  
  """
  def new(id) when is_binary(id), do: _new(id)

  @doc """
  Returns a new Node struct with id and data.
  """
  def new(id, data) when is_binary(id), do: _new(id, data: data)

  #implements creation of a Node struct, optionally setting initial value(s) for Node.adjacent and Node.data fields 
  defp _new(id, opts \\ []) when is_binary(id) do
    %Node{id: id, adjacent: opts[:adjacent] || MapSet.new(), data: opts[:data]}
  end

  @doc """
  """  
  def set_id(node = %Node{}, id) when not is_nil(id), do: %Node{node | id: id}  
  def get_id(%Node{id: id}), do: id

  def set_data(node = %Node{}, data) do
    %Node{node | data: data}
  end
  
  def get_data(%Node{data: data}), do: data


  @doc """
  """  
  def add_adjacent(node = %Node{adjacent: adjacent}, adjNodeID) when is_binary(adjNodeID) do
    %Node{node | adjacent: MapSet.put(adjacent, adjNodeID)}
  end  

  @doc """
  Removes specified adjacent node from a node's adjacency list

  If the specified adjacent node is not in the node's adjacency list, prints an error message and returns nil.
  """  
  def remove_adjacent(node = %Node{adjacent: adjacent}, adjNodeID) do
    if has_adj_node?(node, adjNodeID)  do
      %Node{node | adjacent: MapSet.delete(adjacent, adjNodeID)}
    else
      IO.puts("Error: this node (id: <#{node.id}>) does not contain node with id: <#{adjNodeID}> in its adjacency list.")
      nil
    end
  end

  @doc """
  """
  def has_adj_node?(%Node{adjacent: adjacent}, adjNodeID), do: MapSet.member?(adjacent, adjNodeID)
  
end
   
