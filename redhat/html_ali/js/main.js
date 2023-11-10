const navbarTop = document.querySelector(".top-header"),
  navbarBottom = document.querySelector(".navbar"),
  slide = document.querySelector(".slider"),
  imgHeader = document.querySelector(".img-header"),
  positionHeader = function () {
    (navbarBottom.style.top = `${navbarTop.getBoundingClientRect().height}px`),
      (slide.style.paddingTop = `${
        navbarBottom.getBoundingClientRect().height
      }px`);
  };
positionHeader(), window.addEventListener("resize", positionHeader);
const navLink = document.querySelectorAll(".nav-link");
navLink.forEach((a) => {
  a.addEventListener("click", () => {
    document
      .querySelector("header .navbar .navbar-nav .nav-item .nav-link.active")
      .classList.remove("active"),
      a.classList.add("active");
  });
});
const sectionsAll = document.querySelectorAll("section[id] , header[id]");
window.addEventListener("scroll", () => {
  let a = window.pageYOffset;
  sectionsAll.forEach((b) => {
    let e = b.offsetHeight,
      c = b.offsetTop - 200,
      d = b.getAttribute("id");
    a > c && a < c + e
      ? document
          .querySelector('.nav-item a[href*="' + d + '"]')
          .classList.add("active")
      : document
          .querySelector('.nav-item a[href*="' + d + '"]')
          .classList.remove("active");
  });
});
const nav = document.querySelector("header .navbar"),
  navTop = document.querySelector("header .top-header");
window.addEventListener("scroll", () => {
  window.scrollY > navTop.getBoundingClientRect().height
    ? (nav.classList.add("scroll"),
      nav.classList.add("fixed-top"),
      nav.classList.remove("not-scroll"))
    : (nav.classList.remove("scroll"),
      nav.classList.remove("fixed-top"),
      nav.classList.add("not-scroll"));
}),
  window.scrollY > 100
    ? (nav.classList.add("scroll"),
      nav.classList.add("fixed-top"),
      nav.classList.remove("not-scroll"))
    : (nav.classList.remove("scroll"),
      nav.classList.remove("fixed-top"),
      nav.classList.add("not-scroll")),
  $(window).on("load", function () {
    $("header .navbar .nav-link").on("click", function () {
      $(".navbar-collapse").collapse("hide");
    });
  }),
  $(window).on("load", function () {
    $("#containerOne , #containerTwo").twentytwenty({ no_overlay: !0 });
  });
const animations = () => {
  let a = document.querySelectorAll(".animated");
  a.forEach((a) => {
    let b = a.offsetTop - 0.7 * window.innerHeight;
    window.scrollY >= b &&
      !a.classList.contains("animated_show") &&
      a.classList.add("animated_show");
  });
};
animations(), window.addEventListener("scroll", animations);
