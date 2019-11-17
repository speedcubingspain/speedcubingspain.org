// Setup all tooltips
$(document).on('turbolinks:load', function() {
  $('[data-toggle="tooltip"]').tooltip();
  $(".sort-me").tablesorter();
})

window.aes = window.aes || {};

window.aes.computeSlug = function(title) {
  let normalized = title.normalize('NFD').replace(/[\u0300-\u036f]/g, "");
  normalized = normalized.replace(/['"]/g, "");
  normalized = normalized.replace(/ /g, "-");
  normalized = normalized.toLowerCase();
  return normalized;
}
