# Golden full-platform build trigger

This file intentionally triggers `golden-full-platform-build.yml` after the workflow definition is present on `golden-clean-rebuild`.

The produced artifact is source-rebuilt and remains `DEVICE-TEST-PENDING` until real RG35XX acceptance.
