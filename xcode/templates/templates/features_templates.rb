module Templates
  module FeatureTemplates

    def self.features_enum
"
//MARK: - Feature toggles

public enum Feature: String, Codable, RawRepresentable, CaseIterable {
    <% for @item in @items %>
    case <%= @item %>
    <% end %>
}
"
    end

    def self.enabled_features_extension
"
// MARK: - Enabled features

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