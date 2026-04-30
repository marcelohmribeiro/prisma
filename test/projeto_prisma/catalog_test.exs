defmodule ProjetoPrisma.CatalogTest do
  use ProjetoPrisma.DataCase

  alias ProjetoPrisma.Catalog
  alias ProjetoPrisma.Catalog.Game

  describe "get_or_create_game/1" do
    test "creates games enriched by IGDB id" do
      assert {:ok, %Game{} = game} =
               Catalog.get_or_create_game(%{
                 igdb_id: 123,
                 name: "Portal 2",
                 cover_image: "https://example.com/portal.jpg"
               })

      assert game.igdb_id == 123
      assert game.name == "Portal 2"
    end

    test "allows platform fallback games without IGDB id" do
      attrs = %{
        igdb_id: nil,
        name: "Retro Game",
        icon_image: "https://example.com/retro.png"
      }

      assert {:ok, %Game{} = game} = Catalog.get_or_create_game(attrs)
      assert is_nil(game.igdb_id)
      assert game.name == "Retro Game"

      assert {:ok, %Game{id: same_id}} =
               Catalog.get_or_create_game(%{attrs | icon_image: "https://example.com/new.png"})

      assert same_id == game.id

      assert {:ok, %Game{id: upgraded_id, igdb_id: 456}} =
               Catalog.get_or_create_game(%{name: "Retro Game", igdb_id: 456})

      assert upgraded_id == game.id
    end
  end
end
