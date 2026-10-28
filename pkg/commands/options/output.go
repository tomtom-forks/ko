// Copyright 2026 ko Build Authors All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package options

import (
	"fmt"
	"os"

	"github.com/spf13/cobra"
)

const (
	// OutputText prints the published image references, one per line.
	OutputText = "text"
	// OutputJSON prints a single JSON document describing the build result.
	OutputJSON = "json"
	// OutputGitHub prints the image references like OutputText, and writes the
	// build result as GitHub Actions step outputs. It requires GitHub Actions.
	OutputGitHub = "github"
)

// OutputOptions encapsulates options controlling how results are reported.
type OutputOptions struct {
	// Output is the format of the results written to stdout: "text", "json" or "github".
	Output string
}

// AddOutputArg registers the --output/-O flag, and its hidden --out alias.
func AddOutputArg(cmd *cobra.Command, oo *OutputOptions) {
	cmd.Flags().StringVarP(&oo.Output, "output", "O", OutputText,
		"Format of the results written to stdout: 'text', 'json' (same shape as docker/metadata-action's json output, plus ko extras) or 'github' (text, and the json as step outputs; only in GitHub Actions).")
	// Hidden alias, bound to the same variable.
	cmd.Flags().StringVar(&oo.Output, "out", OutputText, "Alias of --output.")
	_ = cmd.Flags().MarkHidden("out")
}

// Validate checks that the requested output format is supported.
func (oo *OutputOptions) Validate() error {
	switch oo.Output {
	case OutputText, OutputJSON:
		return nil
	case OutputGitHub:
		if os.Getenv("GITHUB_ACTIONS") != "true" {
			return fmt.Errorf("output %q is only available when GITHUB_ACTIONS=true", OutputGitHub)
		}
		if os.Getenv("GITHUB_OUTPUT") == "" {
			return fmt.Errorf("output %q requires the GITHUB_OUTPUT environment variable", OutputGitHub)
		}
		return nil
	default:
		return fmt.Errorf("unsupported output %q (want %q, %q or %q)", oo.Output, OutputText, OutputJSON, OutputGitHub)
	}
}
