defmodule Graph.Node do

  alias Graph.Node

  @moduledoc """
  Documentation for Graph.Node.

  Graph.Node implements a struct to hold the state of a graph node.
  The Graph module builds on Graph.Node to represent graphs out of 
  Node.t structs.

  Struct fields:
  The "id" (generally a binary or an integer) field uniquely identifies 
  a node stored a Graph.t struct.

  The "adjacent" field is a MapSet.t of ids of nodes that are adjacent to the
  node represented by the struct. An id in the adjacent set always represents 
  a directed edge from the node to the adjacent node, regardless of whether the
  graph is directed or undirected (see the Graph module for more info).
  Conceptually, this represents a node's adjacency list.

  The "data" associates some arbitrary data with the node. Thus, the type of value
  stored in this field can be chosen to suit whatever purpose the node/graph is applied to.

  The Node.t struct fields are considered private; 
  do not access them directly, but rather use the interface functions provided.
  """

  # In implementation code, the fields of a Node struct are accessed in whatever way is
  # most convenient (sometimes directly), although clients of the library should only
  # use the public interface functions, as described.

  # Practically speaking, the interface includes a lot of short getters/setters, etc.
  # which are arguably uncessary boilerplate. But ultimately, those functions are implemented 
  # so that this module can define what inputs / operations are valid on the Node struct,
  
  @enforce_keys [:id]
  defstruct id: nil, adjacent: %MapSet{}, data: nil

  @type id :: binary | integer
  @type adjacency_list :: MapSet.t(id)
  @type t() :: %Node{id: id, adjacent: adjacency_list}
  @type t(struct) :: %Node{id: id, adjacent: adjacency_list, data: struct}
  
  @doc """
  Returns a new Node struct with id.  
  """
  def new(id), do: _new(id)

  @doc """
  Returns a new Node struct with id and data.
  """
  def new(id, data), do: _new(id, data: data)

  # implements creation of a Node struct, optionally setting initial value(s)
  # for Node.adjacent and Node.data fields 
  defp _new(id, opts \\ []) do
    %Node{id: id, adjacent: opts[:adjacent] || MapSet.new(), data: opts[:data]}
  end

  @doc """
  Sets the id of a node to the specified id, returning the updated node.
  """  
  def set_id(node = %Node{}, id) when not is_nil(id), do: %Node{node | id: id}

  @doc """
  Returns the id of a node.
  """
  def get_id(%Node{id: id}), do: id

  @doc """
  Sets the node's data field to the specified value and returns the modified node.
  """
  def set_data(node = %Node{}, data) do
    %Node{node | data: data}
  end

  @doc """
  Returns the value of the node's data field.
  """
  def get_data(%Node{data: data}), do: data

  @doc """
  Adds a node id to a node's adjacency list, and returns the updated node.
  """  
  def add_adjacent(node = %Node{adjacent: adjacent}, adjNodeID) do
    %Node{node | adjacent: MapSet.put(adjacent, adjNodeID)}
  end  

  @doc """
  Removes specified adjacent node from a node's adjacency list, and returns the
  updated node.

  If the specified adjacent node is not in the node's adjacency list, 
  prints an error message and returns nil.
  """  
  def remove_adjacent(node = %Node{adjacent: adjacent}, adjNodeID) do
    if has_adj_node?(node, adjNodeID)  do
      %Node{node | adjacent: MapSet.delete(adjacent, adjNodeID)}
    else
      IO.write("Error: this node (id: <#{node.id}>) does not contain ")
      IO.puts("node with id: <#{adjNodeID}> in its adjacency list.")
      nil
    end
  end

  @doc """
  Returns a boolean value indicating whether or not the node has the 
  specified node id in its adjacency list.
  """
  def has_adj_node?(%Node{adjacent: adjacent}, adjNodeID) do
    MapSet.member?(adjacent, adjNodeID)
  end
  
end
   
