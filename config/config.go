/*
NOTE this is a copy of the config package within github.com/gotify/server. Mostly because when
attempting to use it as a plain import if would fail because of a different version of the mode
package being used when building the plugin vs the server.
*/

package config

import (
	"path/filepath"
	"strings"

	"github.com/gotify/configor"
)

// Configuration is stuff that can be configured externally per env variables or config file (config.yml).
type Configuration struct {
	Server struct {
		KeepAlivePeriodSeconds int
		ListenAddr             string `default:""`
		Port                   int    `default:"80"`

		SSL struct {
			Enabled         *bool  `default:"false"`
			RedirectToHTTPS *bool  `default:"true"`
			ListenAddr      string `default:""`
			Port            int    `default:"443"`
			CertFile        string `default:""`
			CertKey         string `default:""`
			LetsEncrypt     struct {
				Enabled   *bool  `default:"false"`
				AcceptTOS *bool  `default:"false"`
				Cache     string `default:"data/certs"`
				Hosts     []string
			}
		}
		ResponseHeaders map[string]string
		Stream          struct {
			PingPeriodSeconds int `default:"45"`
			AllowedOrigins    []string
		}
		Cors struct {
			AllowOrigins []string
			AllowMethods []string
			AllowHeaders []string
		}

		TrustedProxies []string
	}
	Database struct {
		Dialect    string `default:"sqlite3"`
		Connection string `default:"data/gotify.db"`
	}
	DefaultUser struct {
		Name string `default:"admin"`
		Pass string `default:"admin"`
	}
	PassStrength      int    `default:"10"`
	UploadedImagesDir string `default:"data/images"`
	PluginsDir        string `default:"data/plugins"`
	Registration      bool   `default:"false"`
}

func configFiles() []string {
	return []string{"config.yml", "/etc/gotify/config.yml"}
}

// Get returns the configuration extracted from env variables or config file.
func Get() *Configuration {
	conf := new(Configuration)
	err := configor.New(&configor.Config{EnvironmentPrefix: "GOTIFY"}).Load(conf, configFiles()...)
	if err != nil {
		panic(err)
	}
	addTrailingSlashToPaths(conf)
	return conf
}

func addTrailingSlashToPaths(conf *Configuration) {
	if !strings.HasSuffix(conf.UploadedImagesDir, "/") && !strings.HasSuffix(conf.UploadedImagesDir, "\\") {
		conf.UploadedImagesDir += string(filepath.Separator)
	}
}
