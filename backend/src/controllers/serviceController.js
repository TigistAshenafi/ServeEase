import Service from "../models/Service.js";
import Provider from "../models/Provider.js";

export const createService = async (req, res) => {
  try {
    const { title, description, price } = req.body;

    const provider = await Provider.findByUserId(req.user.id);
    if (!provider || provider.status !== "approved")
      return res.status(403).json({ message: "You are not an approved provider" });

    const service = await Service.create(provider.id, title, description, price);

    res.json({ message: "Service created", service });
  } catch (error) {
    console.error("Create Service Error:", error);
    res.status(500).json({ message: "Internal server error" });
  }
};

export const getMyServices = async (req, res) => {
  try {
    const provider = await Provider.findByUserId(req.user.id);

    const services = await Service.findByProvider(provider.id);
    res.json(services);
  } catch (error) {
    console.error("Get Services Error:", error);
    res.status(500).json({ message: "Internal server error" });
  }
};

export const deleteService = async (req, res) => {
  try {
    await Service.delete(req.params.id);
    res.json({ message: "Service deleted" });
  } catch (error) {
    console.error("Delete Service Error:", error);
    res.status(500).json({ message: "Internal server error" });
  }
};
