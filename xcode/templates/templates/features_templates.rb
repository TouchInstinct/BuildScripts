module Templates
  module FeatureTemplates

    def self.features_enum
"
//MARK: - Generated feature toggles

public enum Feature: String, Codable, RawRepresentable, CaseIterable {
    <% for @item in @items %>
    case <%= @item %>
    <% end %>
}
"
    end

    def self.enabled_features_extension
"
// MARK: - Generated enabled features

public extension Feature {

    static var enabled: [Feature] {
        [
          <% for @item in @items %>
          .<%= @item %>,
          <% end %>
        ]
    }
}
"
    end

  end
end