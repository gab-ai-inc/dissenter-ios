// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import Shared
import DissenterShared

extension ShieldsViewController {
    /// The custom loaded view for the `ShieldsViewController`
    class View: UIView {
        private let scrollView = UIScrollView()
        
        let stackView: UIStackView = {
            let sv = UIStackView()
            sv.axis = .vertical
            sv.spacing = 15.0
            sv.layoutMargins = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
            sv.isLayoutMarginsRelativeArrangement = true
            return sv
        }()
        
        // Global Shields Override
        let shieldOverrideControl: ToggleView = {
            let toggleView = ToggleView(title: Strings.Site_shield_settings, toggleSide: .right)
            toggleView.titleLabel.textColor = DissenterUX.GreyJ
            toggleView.titleLabel.font = .systemFont(ofSize: 17.0, weight: .medium)
            return toggleView
        }()
        
        let overviewStackView: OverviewContainerStackView = {
            let sv = OverviewContainerStackView()
            return sv
        }()
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            
            addSubview(scrollView)
            scrollView.addSubview(stackView)
            
            scrollView.snp.makeConstraints {
                $0.edges.equalTo(self)
            }
            
            scrollView.contentLayoutGuide.snp.makeConstraints {
                $0.width.equalTo(self)
            }
            
            stackView.snp.makeConstraints {
                $0.edges.equalTo(scrollView.contentLayoutGuide)
            }
            
            stackView.addArrangedSubview(shieldOverrideControl)
            stackView.addArrangedSubview(overviewStackView)
        }
        
        @available(*, unavailable)
        required init?(coder aDecoder: NSCoder) {
            fatalError()
        }
    }
    
    class OverviewContainerStackView: UIStackView {
        
        let overviewLabel: UILabel = {
            let label = UILabel()
            label.numberOfLines = 0
            label.font = .systemFont(ofSize: 15.0)
            label.text = Strings.Shields_Overview
            return label
        }()
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            axis = .vertical
            spacing = 15.0
            
            addArrangedSubview(overviewLabel)
        }
        
        @available(*, unavailable)
        required init(coder: NSCoder) {
            fatalError()
        }
    }
 
    /// A container displaying a toggle for the user
    class ToggleView: UIView {
        /// Where the toggle resides
        enum ToggleSide {
            /// Resides on the left edge of the view
            case left
            /// Resides on the right edge of the view
            case right
        }
        
        let titleLabel: UILabel = {
            let l = UILabel()
            l.font = .systemFont(ofSize: 15.0)
            l.numberOfLines = 0
            return l
        }()
        
        let toggleSwitch = UISwitch()
        var valueToggled: ((Bool) -> Void)?
        
        init(title: String, toggleSide: ToggleSide = .left) {
            super.init(frame: .zero)
            
            let stackView = UIStackView()
            stackView.spacing = 12.0
            stackView.alignment = .center
            addSubview(stackView)
            stackView.snp.makeConstraints {
                $0.edges.equalTo(self)
            }
            
            if toggleSide == .left {
                stackView.addArrangedSubview(toggleSwitch)
                stackView.addArrangedSubview(titleLabel)
            } else {
                stackView.addArrangedSubview(titleLabel)
                stackView.addArrangedSubview(toggleSwitch)
            }
            
            titleLabel.text = title
            toggleSwitch.addTarget(self, action: #selector(switchValueChanged), for: .valueChanged)
            
            toggleSwitch.setContentHuggingPriority(.required, for: .horizontal)
            toggleSwitch.setContentCompressionResistancePriority(.required, for: .horizontal)
            titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
            
            snp.makeConstraints {
                $0.height.greaterThanOrEqualTo(toggleSwitch)
            }
        }
        
        @available(*, unavailable)
        required init?(coder aDecoder: NSCoder) {
            fatalError()
        }
        
        @objc private func switchValueChanged() {
            valueToggled?(toggleSwitch.isOn)
        }
    }
}
