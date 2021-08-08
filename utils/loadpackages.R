new_libraries <- scan('requirements.txt', what = "")
packages_to_be_installed <- new_libraries[!new_libraries %in% installed.packages()[,'Package']]
if(length(packages_to_be_installed) != 0){
  install.packages(packages_to_be_installed)
}else {
  lapply(new_libraries, library, character.only = TRUE)
}
rm(packages_to_be_installed)
